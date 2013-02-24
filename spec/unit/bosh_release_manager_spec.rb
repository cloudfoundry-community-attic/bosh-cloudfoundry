# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::BoshReleaseManager do
  include Bosh::CloudFoundry::BoshReleaseManager
  include FileUtils

  attr_reader :system_config

  # accessors provided by config_options.rb
  attr_accessor :cf_release_dir, :cf_release_branch, :cf_release_branch_dir

  before do
    @system_dir = File.join(Dir.mktmpdir, "systems", "production")
    @cf_release_dir = File.join(Dir.mktmpdir, "releases", "cf-release")
    mkdir_p(@system_dir)
    @system_config = Bosh::CloudFoundry::Config::SystemConfig.new(@system_dir)
  end

  it "clone_or_update_cf_release - updates master branch" do
    self.cf_release_branch     = "master"
    self.cf_release_branch_dir = File.join(cf_release_dir, "master")
    mkdir_p(cf_release_branch_dir)
    should_receive(:sh).with("git pull origin master")
    should_receive(:sh).with("sed -i 's#git@github.com:#https://github.com/#g' .gitmodules")
    should_receive(:sh).with("sed -i 's#git://github.com#https://github.com#g' .gitmodules")
    should_receive(:sh).with("git submodule update --init --recursive")
    clone_or_update_cf_release
  end

  it "clone_or_update_cf_release - updates staging branch" do
    self.cf_release_branch     = "staging"
    self.cf_release_branch_dir = File.join(cf_release_dir, "staging")
    mkdir_p(cf_release_branch_dir)
    should_receive(:sh).with("git pull origin staging")
    should_receive(:sh).with("sed -i 's#git@github.com:#https://github.com/#g' .gitmodules")
    should_receive(:sh).with("sed -i 's#git://github.com#https://github.com#g' .gitmodules")
    should_receive(:sh).with("git submodule update --init --recursive")
    clone_or_update_cf_release
  end

  describe "switch release types" do
    it "from final to dev" do
      self.cf_release_branch     = "master"
      @system_config.release_name = "appcloud"
      @system_config.release_version = "latest"
      @system_config.save
      switch_to_development_release
      @system_config.release_name.should == "appcloud-master"
      @system_config.release_version.should == "latest"
    end

    it "from dev to final" do
      @system_config.release_name = "appcloud-master"
      @system_config.release_version = "latest"
      @system_config.save
      switch_to_final_release
      @system_config.release_name.should == "appcloud"
      @system_config.release_version.should == "latest"
    end
  end
end
