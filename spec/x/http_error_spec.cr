require "../spec_helper"

describe X::HTTPError do
  it "wraps response" do
    response = SpecHelpers.response(400, "", HTTP::Headers{"Content-Type" => "text/plain"})
    error = X::HTTPError.new(response)
    error.response.should eq response
    error.code.should eq 400
    error.message.should eq "Bad Request"
  end

  it "parses json" do
    headers = HTTP::Headers{"Content-Type" => "application/json"}
    body = "{\"error\":\"boom\"}"
    response = SpecHelpers.response(400, body, headers)
    X::HTTPError.new(response).message.should eq "boom"
  end
end
