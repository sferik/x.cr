require "../spec_helper"

describe X do
  it "has a version" do
    X::VERSION.should_not be_nil
  end

  it "segments array" do
    segs = X::VERSION.split('.')
    segs.size.should be > 0
  end
end
