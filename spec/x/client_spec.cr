require "../spec_helper"

describe X::Client do
  it "defaults" do
    c = X::Client.new
    c.base_url.should eq "https://api.twitter.com/2/"
  end

  it "get request" do
    req_resource = nil
    stub = WebMock.stub(:get, "http://api.twitter.com:443/2/tweets").to_return do |req|
      req_resource = req.resource
      HTTP::Client::Response.new(200, body: "{\"ok\":true}", headers: HTTP::Headers{"Content-Type" => "application/json"})
    end
    c = X::Client.new
    c.get("tweets")
    req_resource.should_not be_nil
    req_resource.not_nil!.should contain("tweets")
    stub.calls.should eq 1
  end
end
