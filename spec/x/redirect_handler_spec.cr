require "../spec_helper"

class StubBuilder < X::RequestBuilder
  getter built = [] of Symbol

  def build(http_method : Symbol, uri : URI, body : String? = nil, headers : Hash(String, String) = Hash(String, String).new, authenticator : X::Authenticator = X::Authenticator.new)
    built << http_method
    HTTP::Request.new(http_method.to_s.upcase, uri.to_s, body: body)
  end
end

describe X::RedirectHandler do
  it "follows redirect" do
    builder = StubBuilder.new
    conn = X::Connection.new
    final_resp = HTTP::Client::Response.new(200)
    stub = WebMock.stub(:get, "http://example.com:443/new").to_return { final_resp }

    rh = X::RedirectHandler.new(conn, builder, 5)
    redirect_resp = SpecHelpers.response(302, "", HTTP::Headers{"Location" => "http://example.com/new"})
    req = HTTP::Request.new("GET", "http://example.com/old")

    rh.handle(redirect_resp, req, "http://example.com").should eq final_resp
    builder.built.should eq [:get]
    stub.calls.should eq 1
  end

  it "too many redirects" do
    builder = StubBuilder.new
    conn = X::Connection.new
    stub = WebMock.stub(:get, "http://example.com:443/new").to_return(status: 302, headers: {"Location" => "http://example.com/new"})

    rh = X::RedirectHandler.new(conn, builder, 1)
    redirect_resp = SpecHelpers.response(302, "", HTTP::Headers{"Location" => "http://example.com/new"})
    req = HTTP::Request.new("GET", "http://example.com/old")

    expect_raises(X::TooManyRedirects) { rh.handle(redirect_resp, req, "http://example.com") }
    stub.calls.should be > 0
  end
end
