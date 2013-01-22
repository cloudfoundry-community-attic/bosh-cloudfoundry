# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::BoshReleaseManager do
  include Bosh::CloudFoundry::BoshReleaseManager
  include FileUtils

  attr_reader :system_config

  before do
    @system_dir = File.join(Dir.mktmpdir, "systems", "production")
    mkdir_p(@system_dir)
    @system_config = Bosh::CloudFoundry::Config::SystemConfig.new(@system_dir)
  end

  describe "switch release types" do
    it "from final to dev" do
      @system_config.release_name = "appcloud"
      @system_config.release_version = "latest"
      @system_config.save
      switch_to_development_release
      @system_config.release_name.should == "appcloud-dev"
      @system_config.release_version.should == "latest"
    end

    it "from dev to final" do
      @system_config.release_name = "appcloud-dev"
      @system_config.release_version = "latest"
      @system_config.save
      switch_to_final_release
      @system_config.release_name.should == "appcloud"
      @system_config.release_version.should == "latest"
    end
  end
end
