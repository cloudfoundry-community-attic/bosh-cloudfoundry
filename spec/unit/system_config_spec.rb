# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::SystemConfig do
  before(:each) do
    @dir = Dir.mktmpdir("system_config_spec")
    @config = Bosh::CloudFoundry::SystemConfig.new(@dir)
  end

  after(:each) do
    FileUtils.remove_entry_secure @dir
  end

  it("has system_name attribute") { @config.system_name.should_not == nil }
  it("has system_dir attribute") { @config.system_dir.should_not == nil }
  it("has release_name attribute") { @config.release_name.should == nil }
  it("has stemcell_version attribute") { @config.stemcell_version.should == nil }
  it("has runtimes attribute") { @config.runtimes.should == nil }

  it "defaults system_name attribute based on basename of location of config file" do
    @config.system_name == File.basename(@dir)
  end

  it "defaults system_dir attribute based on location of config file" do
    @config.system_dir == @dir
  end
end
