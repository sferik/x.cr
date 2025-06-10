require "../spec_helper"

describe X::RequestBuilder do
  it "builds get request" do
    rb = X::RequestBuilder.new
    auth = X::Authenticator.new
    uri = URI.parse("http://example.com/path?foo=bar")
    req = rb.build(:get, uri, authenticator: auth)
    req.method.should eq "GET"
    req.resource.should contain("foo%3Dbar")
  end

  it "custom headers" do
    rb = X::RequestBuilder.new
    uri = URI.parse("http://example.com")
    req = rb.build(:get, uri, headers: {"User-Agent" => "UA"})
    req.headers["User-Agent"].should eq "UA"
  end

  it "unsupported method" do
    rb = X::RequestBuilder.new
    uri = URI.parse("http://example.com")
    expect_raises(ArgumentError) { rb.build(:patch, uri) }
  end
end
