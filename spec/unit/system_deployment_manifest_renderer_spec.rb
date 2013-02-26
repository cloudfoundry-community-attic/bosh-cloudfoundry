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
    @system_config.bosh_target = "http://6.7.8.9:25555"
    @system_config.bosh_target_uuid = "DIRECTOR_UUID"
    @system_config.bosh_provider = 'aws'
    @system_config.release_name = 'appcloud'
    @system_config.release_version = 'latest'
    @system_config.stemcell_name = 'bosh-stemcell'
    @system_config.stemcell_version = '0.7.0'
    @system_config.core_server_flavor = 'm1.small'
    @system_config.core_ip = '1.2.3.4'
    @system_config.root_dns = 'mycompany.com'
    @system_config.admin_emails = ['drnic@starkandwayne.com']
    @system_config.common_password = 'c1oudc0wc1oudc0w'
    @system_config.common_persistent_disk = 16192
    @system_config.security_group = 'cloudfoundry-production'

    @renderer = Bosh::CloudFoundry::SystemDeploymentManifestRenderer.new(
      @system_config, @common_config, @bosh_config)

    Bosh::CloudFoundry::Providers.should_receive(:for_bosh_provider_name).
      and_return(Bosh::CloudFoundry::Providers::AWS.new)
    # 
    # @dea_config = @renderer.dea_config
    # @dea_config.should_receive(:ram_for_server_flavor).and_return(1700)
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

    it "renders a simple system + redis into a deployment manifest" do
      @system_config.redis = [
        { "count" => 1, "flavor" => "m1.small", "plan" =>"free" },
      ]
      @renderer.perform
    
      chdir(@system_config.system_dir) do
        File.should be_exist("deployments/production-core.yml")
        files_match("deployments/production-core.yml",
                    spec_asset("deployments/aws-core-1-m1.small-free-redis.yml"))
      end
    end
  end
end
