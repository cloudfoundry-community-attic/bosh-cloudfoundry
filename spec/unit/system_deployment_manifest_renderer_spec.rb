# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::SystemDeploymentManifestRenderer do
  include FileUtils

  before(:each) do
    @home_dir = Dir.mktmpdir("home")
    common_config_file = File.join(@home_dir, "cf_config")
    @common_config =  Bosh::CloudFoundry::Config:: CommonConfig.new(common_config_file)

    bosh_config_file = File.join(@home_dir, "bosh_config")
    @bosh_config =  Bosh::Cli::Config.new(bosh_config_file)
    @bosh_config.target_uuid = "DIRECTOR_UUID"
    @bosh_config.save
    
    @systems_dir = Dir.mktmpdir("system_config")
    @system_dir = File.join(@systems_dir, "production")
    mkdir_p(@system_dir)
    @system_config = Bosh::CloudFoundry::Config::SystemConfig.new(@system_dir)
    @system_config.bosh_provider = 'aws'
    @system_config.release_name = 'appcloud'
    @system_config.release_version = 'latest'
    @system_config.stemcell_name = 'bosh-stemcell'
    @system_config.stemcell_version = '0.6.4'
    @system_config.core_server_flavor = 'm1.small'
    @system_config.core_ip = '1.2.3.4'
    @system_config.root_dns = 'mycompany.com'
    @system_config.admin_emails = ['drnic@starkandwayne.com']
    @system_config.common_password = 'c1oudc0wc1oudc0w'
    @system_config.common_persistent_disk = 16192
    @system_config.aws_security_group = 'default'
    @renderer = Bosh::CloudFoundry::SystemDeploymentManifestRenderer.new(
      @system_config, @common_config, @bosh_config)
  end

  after(:each) do
    FileUtils.remove_entry_secure @systems_dir
    @renderer = nil
  end

  describe "rendering deployment manifest(s)" do
    it "renders a base system without DEAs/services into a deployment manifest" do
      @renderer.perform

      chdir(@system_config.system_dir) do
        File.should be_exist("deployments/production-core.yml")
        files_match("deployments/production-core.yml", spec_asset("deployments/aws-core-only.yml"))
      end
    end
    it "renders a simple system + DEAs into a deployment manifest" do
      @system_config.dea = { "count" => 2, "flavor" => "m1.xlarge" }
      @renderer.perform
    
      chdir(@system_config.system_dir) do
        File.should be_exist("deployments/production-core.yml")
        files_match("deployments/production-core.yml",
                    spec_asset("deployments/aws-core-2-m1.xlarge-dea.yml"))
      end
    end

    it "renders a simple system + postgresql into a deployment manifest" do
      @system_config.postgresql = [
        { "count" => 1, "flavor" => "m1.xlarge", "plan" =>"free" },
        { "count" => 2, "flavor" => "m1.small", "plan" =>"free" },
      ]
      @renderer.perform
    
      chdir(@system_config.system_dir) do
        File.should be_exist("deployments/production-core.yml")
        files_match("deployments/production-core.yml",
                    spec_asset("deployments/aws-core-1-m1.xlarge-free-postgresql-2-m1.small-free-postgresql.yml"))
      end
    end

    # it "renders a simple system + postgresql + redis into a deployment manifest"
  end
end
