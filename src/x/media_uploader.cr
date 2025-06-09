require "json"

module X
  module MediaUploader
    extend self

    MAX_RETRIES  =         3
    BYTES_PER_MB = 1_048_576

    DM_GIF           = "dm_gif"
    DM_IMAGE         = "dm_image"
    DM_VIDEO         = "dm_video"
    SUBTITLES        = "subtitles"
    TWEET_GIF        = "tweet_gif"
    TWEET_IMAGE      = "tweet_image"
    TWEET_VIDEO      = "tweet_video"
    MEDIA_CATEGORIES = [DM_GIF, DM_IMAGE, DM_VIDEO, SUBTITLES, TWEET_GIF, TWEET_IMAGE, TWEET_VIDEO]

    DEFAULT_MIME_TYPE = "application/octet-stream"
    GIF_MIME_TYPE     = "image/gif"
    JPEG_MIME_TYPE    = "image/jpeg"
    MP4_MIME_TYPE     = "video/mp4"
    PNG_MIME_TYPE     = "image/png"
    SUBRIP_MIME_TYPE  = "application/x-subrip"
    WEBP_MIME_TYPE    = "image/webp"
    MIME_TYPES        = [GIF_MIME_TYPE, JPEG_MIME_TYPE, MP4_MIME_TYPE, PNG_MIME_TYPE, SUBRIP_MIME_TYPE, WEBP_MIME_TYPE]
    MIME_TYPE_MAP     = {
      "gif"  => GIF_MIME_TYPE,
      "jpg"  => JPEG_MIME_TYPE,
      "jpeg" => JPEG_MIME_TYPE,
      "mp4"  => MP4_MIME_TYPE,
      "png"  => PNG_MIME_TYPE,
      "srt"  => SUBRIP_MIME_TYPE,
      "webp" => WEBP_MIME_TYPE,
    }

    PROCESSING_INFO_STATES = ["failed", "succeeded"]

    def upload(client : Client, file_path : String, media_category : String, boundary = Random::Secure.hex)
      validate!(file_path, media_category)
      upload_body = construct_upload_body(file_path, media_category: media_category, boundary: boundary)
      headers = {"Content-Type" => "multipart/form-data; boundary=#{boundary}"}
      client.post("media/upload", upload_body, headers: headers).try(&.as_h["data"]?)
    end

    def chunked_upload(client : Client, file_path : String, media_category : String, media_type = infer_media_type(file_path, media_category), boundary = Random::Secure.hex, chunk_size_mb = 1)
      validate!(file_path, media_category)
      media = init(client, file_path, media_type, media_category)
      chunk_size = (chunk_size_mb * BYTES_PER_MB).ceil.to_i
      append(client, split(file_path, chunk_size), media, boundary: boundary)
      media_id = extract_media_id(media)
      client.post("media/upload/#{media_id}/finalize").try(&.as_h["data"]?)
    end

    def await_processing(client : Client, media)
      loop do
        media_id = extract_media_id(media)
        status = client.get("media/upload?command=STATUS&media_id=#{media_id}").try(&.as_h["data"]?)
        return status if status.nil? || status["processing_info"].nil? || PROCESSING_INFO_STATES.includes?(status["processing_info"]["state"].to_s)
        sleep status["processing_info"]["check_after_secs"].as_i
      end
    end

    def await_processing!(client : Client, media)
      status = await_processing(client, media)
      if status && status["processing_info"]? && status["processing_info"]["state"] == "failed"
        raise RuntimeError.new("Media processing failed")
      end
      status
    end

    private def validate!(file_path : String, media_category : String)
      raise "File not found: #{file_path}" unless File.exists?(file_path)
      return if MEDIA_CATEGORIES.includes?(media_category.downcase)
      raise ArgumentError.new("Invalid media_category: #{media_category}. Valid values: #{MEDIA_CATEGORIES.join(", ")}")
    end

    private def infer_media_type(file_path : String, media_category : String)
      case media_category.downcase
      when TWEET_GIF, DM_GIF
        GIF_MIME_TYPE
      when TWEET_VIDEO, DM_VIDEO
        MP4_MIME_TYPE
      when SUBTITLES
        SUBRIP_MIME_TYPE
      else
        MIME_TYPE_MAP.fetch(File.extname(file_path).delete('.').downcase, DEFAULT_MIME_TYPE)
      end
    end

    private def split(file_path : String, chunk_size : Int32)
      segments = [] of String
      File.open(file_path) do |io|
        buffer = Bytes.new(chunk_size)
        index = 0
        while (read_bytes = io.read(buffer)) > 0
          dir = File.tempname("x", nil, dir: Dir.tempdir)
          Dir.mkdir(dir)
          segment_path = File.join(dir, "x%03d" % (index + 1))
          File.open(segment_path, "wb") { |f| f.write(buffer[0, read_bytes]) }
          segments << segment_path
          index += 1
        end
      end
      segments
    end

    private def init(client : Client, file_path : String, media_type : String, media_category : String)
      total_bytes = File.size(file_path)
      data = {media_type: media_type, media_category: media_category, total_bytes: total_bytes}.to_json
      client.post("media/upload/initialize", data).try(&.as_h["data"]?)
    end

    private def append(client : Client, file_paths : Array(String), media, boundary = Random::Secure.hex)
      file_paths.each_with_index do |file_path, index|
        upload_body = construct_upload_body(file_path, segment_index: index, boundary: boundary)
        headers = {"Content-Type" => "multipart/form-data; boundary=#{boundary}"}
        upload_chunk(client, media.not_nil!.as_h["id"].to_s, upload_body, file_path, headers: headers)
      end
    end

    private def upload_chunk(client : Client, media_id : String, upload_body : String, file_path : String, headers = {} of String => String)
      retries = 0
      begin
        loop do
          begin
            client.post("media/upload/#{media_id}/append", upload_body, headers: headers)
            break
          rescue ex : NetworkError | ServerError
            retries += 1
            raise ex if retries >= MAX_RETRIES
          end
        end
      ensure
        cleanup_file(file_path)
      end
    end

    private def cleanup_file(file_path : String)
      dirname = File.dirname(file_path)
      File.delete(file_path) rescue nil
      Dir.delete(dirname) if Dir.exists?(dirname) && Dir.empty?(dirname) rescue nil
    end

    private def construct_upload_body(file_path : String, media_category : String? = nil, segment_index : Int32? = nil, boundary = Random::Secure.hex)
      body = String.build do |io|
        if segment_index
          io << "--#{boundary}\r\n"
          io << "Content-Disposition: form-data; name=\"segment_index\"\r\n\r\n#{segment_index}\r\n"
        end
        if media_category
          io << "--#{boundary}\r\n"
          io << "Content-Disposition: form-data; name=\"media_category\"\r\n\r\n#{media_category}\r\n"
        end
        io << "--#{boundary}\r\n"
        io << "Content-Disposition: form-data; name=\"media\"; filename=\"#{File.basename(file_path)}\"\r\n"
        io << "Content-Type: #{DEFAULT_MIME_TYPE}\r\n\r\n"
        io << File.read(file_path)
        io << "\r\n--#{boundary}--\r\n"
      end
      body
    end

    private def extract_media_id(media)
      if h = media.as?(Hash)
        h["id"]?
      else
        media.as?(JSON::Any).try(&.as_h["id"]) || ""
      end
    end
  end
end
