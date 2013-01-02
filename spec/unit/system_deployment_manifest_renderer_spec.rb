# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::SystemDeploymentManifestRenderer do
  include FileUtils

  before(:each) do
    @dir = Dir.mktmpdir("system_config_spec")
    @system_dir = File.join(@dir, "production")
    mkdir_p(@system_dir)
    @config = Bosh::CloudFoundry::SystemConfig.new(@system_dir)
    @config.bosh_provider = 'aws'
    @config.release_name = 'appcloud'
    @config.stemcell_version = '0.6.4'
    @config.core_server_flavor = 'm1.small'
    @config.core_ip = '1.2.3.4'
    @config.root_dns = 'mycompany.com'
    @renderer = Bosh::CloudFoundry::SystemDeploymentManifestRenderer.new(@config)
  end

  after(:each) do
    FileUtils.remove_entry_secure @dir
    @renderer = nil
  end

  describe "rendering deployment manifest(s)" do
    it "renders a base system without DEAs/services into a deployment manifest" do
      @renderer.perform

      chdir(@config.system_dir) do
        File.should be_exist("deployments/production-core.yml")
        files_match("deployments/production-core.yml", spec_asset("deployments/production-core.yml"))
      end
    end
    it "renders a simple system + DEAs into a deployment manifest"
    it "renders a simple system + postgresql into a deployment manifest"
    it "renders a simple system + postgresql + redis into a deployment manifest"
    it "renders a micro system into a deployment manifest"
  end
end
