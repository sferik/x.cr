require "../spec_helper"

describe X::Connection do
  it "performs request" do
    stub = WebMock.stub(:get, "http://example.com:443/").to_return(status: 200)
    conn = X::Connection.new
    req = HTTP::Request.new("GET", "http://example.com")
    resp = conn.perform(req)
    resp.status_code.should eq 200
    stub.calls.should eq 1
  end

  it "raises network error" do
    conn = X::Connection.new
    req = HTTP::Request.new("GET", "http://example.com")
    expect_raises(X::NetworkError) { conn.perform(req) }
  end

  it "sets proxy" do
    conn = X::Connection.new
    conn.proxy_url = "http://user:pass@example.com:8080"
    conn.proxy_uri.not_nil!.host.should eq "example.com"
  end
end
