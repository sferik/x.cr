require "../spec_helper"

describe X::BearerTokenAuthenticator do
  it "adds token" do
    auth = X::BearerTokenAuthenticator.new(TEST_BEARER_TOKEN)
    header = auth.header(nil)
    header[X::Authenticator::AUTHENTICATION_HEADER].should eq "Bearer #{TEST_BEARER_TOKEN}"
  end
end
