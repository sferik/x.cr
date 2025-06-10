require "../spec_helper"

describe X::RateLimit do
  it "computes reset" do
    headers = HTTP::Headers{
      "x-rate-limit-limit"     => "100",
      "x-rate-limit-remaining" => "0",
      "x-rate-limit-reset"     => (Time.utc(1983, 11, 24) + 60.seconds).to_unix.to_s,
    }
    response = SpecHelpers.response(200, "", headers)
    rl = X::RateLimit.new(X::RateLimit::Type::RateLimit, response)
    rl.limit.should eq 100
    rl.remaining.should eq 0
    rl.reset_in.should be >= 0
  end
end
