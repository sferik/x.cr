require "../spec_helper"

class TestOAuth < X::OAuthAuthenticator
  def default_oauth_params
    {
      "oauth_consumer_key"     => TEST_API_KEY,
      "oauth_nonce"            => TEST_OAUTH_NONCE,
      "oauth_signature_method" => X::OAuthAuthenticator::OAUTH_SIGNATURE_METHOD,
      "oauth_timestamp"        => TEST_OAUTH_TIMESTAMP,
      "oauth_token"            => TEST_ACCESS_TOKEN,
      "oauth_version"          => X::OAuthAuthenticator::OAUTH_VERSION,
    }
  end
end

describe X::OAuthAuthenticator do
  it "builds header" do
    request = HTTP::Request.new("GET", "https://example.com/?query=test")
    auth = TestOAuth.new(TEST_API_KEY, TEST_API_KEY_SECRET, TEST_ACCESS_TOKEN, TEST_ACCESS_TOKEN_SECRET)
    header = auth.header(request)[X::Authenticator::AUTHENTICATION_HEADER]
    header.should contain("oauth_consumer_key=\"#{TEST_API_KEY}\"")
    header.should contain("oauth_signature_method=\"HMAC-SHA1\"")
  end
end
