require "../spec_helper"
require "json"

BOUNDARY     = "AaB03x"
BASE_URL     = "https://api.twitter.com/2/media/upload"
JSON_BODY    = {"data" => {"id" => TEST_MEDIA_ID}}.to_json
JSON_HEADERS = {"Content-Type" => "application/json"}

class StubClient < X::Client
  getter posts = [] of NamedTuple(endpoint: String, body: String?, headers: Hash(String, String))
  getter gets = [] of NamedTuple(endpoint: String)
  property raise_next_post : Bool = false
  property raise_on_append : Bool = false

  def initialize(@responses : Array(JSON::Any?))
    super()
  end

  def post(endpoint : String, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, *, array_class = Array, object_class = Hash)
    posts << {endpoint: endpoint, body: body, headers: headers}
    if raise_next_post || (raise_on_append && endpoint.includes?("/append"))
      @raise_next_post = false
      @raise_on_append = false if endpoint.includes?("/append")
      raise X::NetworkError.new("fail")
    end
    @responses.shift?
  end

  def get(endpoint : String, headers : Hash(String, String) = Hash(String, String).new, *, array_class = Array, object_class = Hash)
    gets << {endpoint: endpoint}
    @responses.shift
  end
end

describe X::MediaUploader do
  it "upload" do
    client = StubClient.new([JSON.parse(JSON_BODY)] of JSON::Any?)
    file_path = "test/sample_files/sample.jpg"
    resp = X::MediaUploader.upload(client, file_path, X::MediaUploader::TWEET_IMAGE, BOUNDARY)
    client.posts.size.should eq 1
    client.posts[0][:endpoint].should eq "media/upload"
    client.posts[0][:body].not_nil!.should contain(X::MediaUploader::TWEET_IMAGE)
    resp.not_nil!.as_h["id"].as_s.should eq TEST_MEDIA_ID
  end

  it "chunked upload" do
    file_path = "test/sample_files/sample.mp4"
    responses = [JSON.parse(JSON_BODY), nil, nil, JSON.parse(JSON_BODY)] of JSON::Any?
    client = StubClient.new(responses)
    chunk_size = (File.size(file_path) - 1) / X::MediaUploader::BYTES_PER_MB.to_f
    X::MediaUploader.chunked_upload(client, file_path, X::MediaUploader::TWEET_VIDEO, boundary: BOUNDARY, chunk_size_mb: chunk_size)
    client.posts[0][:endpoint].should eq "media/upload/initialize"
    client.posts.last[:endpoint].should eq "media/upload/#{TEST_MEDIA_ID}/finalize"
  end

  it "await processing" do
    responses = [JSON.parse("{\"data\":{\"processing_info\":{\"state\":\"pending\",\"check_after_secs\":0}}}"), JSON.parse("{\"data\":{\"processing_info\":{\"state\":\"succeeded\"}}}")] of JSON::Any?
    client = StubClient.new(responses)
    result = X::MediaUploader.await_processing(client, {"id" => TEST_MEDIA_ID})
    result.not_nil!.as_h["processing_info"].as_h["state"].as_s.should eq "succeeded"
  end

  it "await processing failure" do
    responses = [JSON.parse("{\"data\":{\"processing_info\":{\"state\":\"pending\",\"check_after_secs\":0}}}"), JSON.parse("{\"data\":{\"processing_info\":{\"state\":\"failed\"}}}")] of JSON::Any?
    client = StubClient.new(responses)
    expect_raises(RuntimeError) { X::MediaUploader.await_processing!(client, {"id" => TEST_MEDIA_ID}) }
  end

  it "retry upload" do
    file_path = "test/sample_files/sample.mp4"
    responses = [JSON.parse(JSON_BODY), nil, nil, JSON.parse(JSON_BODY)] of JSON::Any?
    client = StubClient.new(responses)
    client.raise_on_append = true
    X::MediaUploader.chunked_upload(client, file_path, X::MediaUploader::TWEET_VIDEO, boundary: BOUNDARY, chunk_size_mb: 0.001)
    client.posts.select { |p| p[:endpoint].ends_with?("/append") }.size.should be >= 2
  end
end
