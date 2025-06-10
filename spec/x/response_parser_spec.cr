require "../spec_helper"

describe X::ResponseParser do
  it "parses json" do
    rp = X::ResponseParser.new
    headers = HTTP::Headers{"Content-Type" => "application/json"}
    resp = SpecHelpers.response(200, "{\"value\":1}", headers)
    rp.parse(resp).as(JSON::Any)["value"].as_i.should eq 1
  end

  it "returns nil for non-json" do
    rp = X::ResponseParser.new
    headers = HTTP::Headers{"Content-Type" => "text/plain"}
    resp = SpecHelpers.response(200, "ok", headers)
    rp.parse(resp).should be_nil
  end

  it "raises error" do
    rp = X::ResponseParser.new
    resp = SpecHelpers.response(400)
    expect_raises(X::BadRequest) { rp.parse(resp) }
  end

  it "too many requests" do
    rp = X::ResponseParser.new
    headers = HTTP::Headers{"x-rate-limit-remaining" => "0"}
    resp = SpecHelpers.response(429, "", headers)
    ex = expect_raises(X::TooManyRequests) { rp.parse(resp) }
    ex.rate_limits.size.should eq 1
  end
end
