# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::Cli::Command::Base do

  before :each do
    @config = File.join(Dir.mktmpdir, "bosh_config")
    @cf_config = File.join(Dir.mktmpdir, "bosh_cf_config")
    @cache = File.join(Dir.mktmpdir, "bosh_cache")
    @systems_dir = File.join(Dir.mktmpdir, "systems")
    @releases_dir = File.join(Dir.mktmpdir, "releases")
  end

  describe Bosh::Cli::Command::CloudFoundry do

    before :each do
      @cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
      @cmd.add_option(:non_interactive, true)
      @cmd.add_option(:config, @config)
      @cmd.add_option(:cf_config, @cf_config)
      @cmd.add_option(:cache_dir, @cache)
      @cmd.add_option(:base_systems_dir, @systems_dir)
    end

    it "sets/gets the target system" do
      @cmd.system.should be_nil
      FileUtils.mkdir_p(File.join(@systems_dir, "production"))
      @cmd.set_system("production")
      File.basename(@cmd.system).should == "production"
      File.should be_directory(@cmd.system)
    end

    it "updates/creates/uploads cf-release" do
      cf_releases_dir = File.join(@releases_dir, "cf-release")
      FileUtils.mkdir_p(cf_releases_dir)
      @cmd.add_option(:cf_release_dir, @releases_dir)

      @cmd.should_receive(:sh).with("git pull origin master")
      @cmd.should_receive(:sh).with("bosh create release")
      @cmd.should_receive(:sh).with("bosh upload release")
      @cmd.public_cloudfoundry
    end

    it "generates new system folder/manifests, using all options" do
      @cmd.stub!(:confirm_bosh_target).and_return(true)
      @cmd.stub!(:bosh_releases).and_return(['cf-dev', 'cf-production'])

      @cmd.add_option(:ip, ['1.2.3.4'])
      @cmd.add_option(:dns, 'mycompany.com')
      @cmd.add_option(:cf_release, 'cf-dev')

      @cmd.system.should be_nil
      @cmd.new_system("production")
      File.basename(@cmd.system).should == "production"
    end
  end
end