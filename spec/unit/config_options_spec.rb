# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::ConfigOptions do
  include Bosh::CloudFoundry::ConfigOptions
  include FileUtils
  attr_reader :options

  before do
    @options = {
      :common_config => File.join(Dir.mktmpdir, "bosh_common_config.yml"),
      :system => File.join(Dir.mktmpdir, "system"),
    }
    mkdir_p(@options[:system])
  end

  describe "common_config attribute" do
    
  end

  describe "system_config attribute" do
    it "release_name can be overridden but is stored in system_config" do
      options[:release_name] = "CHANGED"
      release_name.should == "CHANGED"
      system_config.release_name.should == "CHANGED"
    end

    it "stemcell_version can be overridden but is stored in system_config" do
      options[:stemcell_version] = "CHANGED"
      stemcell_version.should == "CHANGED"
      system_config.stemcell_version.should == "CHANGED"
    end

    it "core_ip can be overridden but is stored in system_config" do
      options[:core_ip] = "CHANGED"
      core_ip.should == "CHANGED"
      system_config.core_ip.should == "CHANGED"
    end

    it "root_dns can be overridden but is stored in system_config" do
      options[:root_dns] = "CHANGED"
      root_dns.should == "CHANGED"
      system_config.root_dns.should == "CHANGED"
    end

    it "core_server_flavor can be overridden but is stored in system_config" do
      options[:core_server_flavor] = "CHANGED"
      core_server_flavor.should == "CHANGED"
      system_config.core_server_flavor.should == "CHANGED"
    end
  end
end
