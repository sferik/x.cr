require "../spec_helper"

describe X::Authenticator do
  it "returns empty header" do
    auth = X::Authenticator.new
    header = auth.header(nil)
    header[X::Authenticator::AUTHENTICATION_HEADER].should eq ""
  end
end
