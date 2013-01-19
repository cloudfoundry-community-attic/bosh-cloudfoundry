# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::Config::MicroboshConfig do
  before(:each) do
    @home = Dir.mktmpdir("home")
  end

  it "discovers fog connection properties in an AWS micro_bosh.yml"
end
