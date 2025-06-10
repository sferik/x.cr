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
file_path = "path/to/your/media.jpg"
media_category = "tweet_image" # other options are: dm_image or subtitles; for videos or GIFs use chunked_upload

media = X::MediaUploader.upload(client: client, file_path: file_path, media_category: media_category)

tweet_body = {"text" => "Posting media from @shard!", "media" => {"media_ids" => [media["id"]]}}

tweet = client.post("tweets", tweet_body.to_json)

puts tweet["data"]["id"]
