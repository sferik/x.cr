require "../spec_helper"

describe X::TooManyRequests do
  it "collects limits" do
    headers = HTTP::Headers{
      "x-rate-limit-limit"     => "100",
      "x-rate-limit-remaining" => "0",
      "x-rate-limit-reset"     => (Time.utc + 60.seconds).to_unix.to_s,
    }
    response = SpecHelpers.response(429, "", headers)
    ex = X::TooManyRequests.new(response)
    ex.reset_in.should be >= 0
    ex.rate_limits.size.should eq 1
  end
end
