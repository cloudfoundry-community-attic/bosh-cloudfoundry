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
    base_systems_dir = File.join(@dir, "systems")
    Bosh::CloudFoundry::Config.configure({"base_systems_dir" => base_systems_dir})

    base_systems_dir = Bosh::CloudFoundry::Config.base_systems_dir
    base_systems_dir.should == base_systems_dir
    File.exists?(base_systems_dir).should == true
  end
end
