require "http/client"
require "spec"
require "webmock"
require "../src/x.cr"

TEST_BEARER_TOKEN        = "TEST_BEARER_TOKEN"
TEST_API_KEY             = "TEST_API_KEY"
TEST_API_KEY_SECRET      = "TEST_API_KEY_SECRET"
TEST_ACCESS_TOKEN        = "TEST_ACCESS_TOKEN"
TEST_ACCESS_TOKEN_SECRET = "TEST_ACCESS_TOKEN_SECRET"
TEST_OAUTH_NONCE         = "TEST_OAUTH_NONCE"
TEST_OAUTH_TIMESTAMP     = Time.utc(1983, 11, 24).to_unix.to_s
TEST_MEDIA_ID            = "TEST_MEDIA_ID"

# Helper to build HTTP responses easily
module SpecHelpers
  def self.response(status : Int32, body = "", headers = HTTP::Headers.new)
    HTTP::Client::Response.new(status, body, headers)
  end
end

Spec.before_each &->WebMock.reset
