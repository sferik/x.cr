require "x"

x_credentials = {
  api_key:             "INSERT YOUR X API KEY HERE",
  api_key_secret:      "INSERT YOUR X API KEY SECRET HERE",
  access_token:        "INSERT YOUR X ACCESS TOKEN HERE",
  access_token_secret: "INSERT YOUR X ACCESS TOKEN SECRET HERE",
}

client = X::Client.new(**x_credentials, base_url: "https://api.twitter.com/1.1/")

screen_name = "sferik"
count = 5000
cursor = -1
follower_ids = [] of Int64

loop do
  begin
    response = client.get("followers/ids.json?screen_name=#{screen_name}&count=#{count}&cursor=#{cursor}")
    follower_ids.concat(response["ids"].as(Array(Int64)))
    cursor = response["next_cursor"].as(Int64)
    break if cursor == 0
  rescue e : X::TooManyRequests
    # NOTE: sleeping up to 15 minutes may be necessary
    sleep e.retry_after
    retry
  end
end
