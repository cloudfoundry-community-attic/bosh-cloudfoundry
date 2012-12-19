# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::Cli::Command::Base do

  before :each do
    @config = File.join(Dir.mktmpdir, "bosh_config")
    @cache = File.join(Dir.mktmpdir, "bosh_cache")
    @systems_dir = File.join(Dir.mktmpdir, "systems")
  end

  describe Bosh::Cli::Command::CloudFoundry do

    before :each do
      @cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
      @cmd.add_option(:non_interactive, true)
      @cmd.add_option(:config, @config)
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

    it "generates new system folder/manifests" do
      
    end
  end
end