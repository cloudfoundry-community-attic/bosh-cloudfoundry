# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::Config do
  before(:each) do
    @dir = Dir.mktmpdir("bcf_config_spec")
  end

  after(:each) do
    FileUtils.remove_entry_secure @dir
  end

  it "should default base_systems_dir and create it" do
    config_file = File.join(@dir, "config.yml")
    config = Bosh::CloudFoundry::Config.new(config_file)

    base_systems_dir = config.base_systems_dir
    base_systems_dir.should == nil
  end
end
