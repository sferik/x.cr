require "x"
require "x/media_uploader"
require "json"

x_credentials = {
  api_key:             "INSERT YOUR X API KEY HERE",
  api_key_secret:      "INSERT YOUR X API KEY SECRET HERE",
  access_token:        "INSERT YOUR X ACCESS TOKEN HERE",
  access_token_secret: "INSERT YOUR X ACCESS TOKEN SECRET HERE",
}

client = X::Client.new(**x_credentials)
file_path = "path/to/your/media.mp4"
media_category = "tweet_video" # other options include: tweet_image, tweet_gif, dm_image, dm_video, dm_gif, subtitles

media = X::MediaUploader.chunked_upload(client: client, file_path: file_path, media_category: media_category)

X::MediaUploader.await_processing(client: client, media: media) # or await_processing!(...) to raise on error

tweet_body = {"text" => "Posting media from @shard!", "media" => {"media_ids" => [media["id"]]}}

tweet = client.post("tweets", tweet_body.to_json)

puts tweet["data"]["id"]
