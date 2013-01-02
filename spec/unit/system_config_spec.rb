# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::SystemConfig do
  before(:each) do
    @dir = Dir.mktmpdir("system_config_spec")
    config_file = File.join(@dir, "config.yml")
    @config = Bosh::CloudFoundry::SystemConfig.new(config_file)
  end

  after(:each) do
    FileUtils.remove_entry_secure @dir
  end

  it "has system_name attribute" do
    @config.system_name.should == nil
  end

  it "has system_dir attribute" do
    @config.system_dir.should == nil
  end

  it "has release_name attribute" do
    @config.release_name.should == nil
  end

  it "has stemcell_version attribute" do
    @config.stemcell_version.should == nil
  end

  it "has known runtimes attribute" do
    @config.runtimes.should == nil
  end
end
