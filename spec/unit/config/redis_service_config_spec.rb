# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../../spec_helper", __FILE__)

# The specification of how a user's redis choices (count & flavor)
# are converted into deployment manifest configuration
describe Bosh::CloudFoundry::Config::RedisServiceConfig do
  include FileUtils

  before do
    @systems_dir = Dir.mktmpdir("system_config")
    @system_dir = File.join(@systems_dir, "production")
    mkdir_p(@system_dir)
    @system_config = Bosh::CloudFoundry::Config::SystemConfig.new(@system_dir)
    @system_config.bosh_provider = "aws"
    @manifest = YAML.load_file(spec_asset("deployments/aws-core-only.yml"))
  end

  # find a specificly named job in the manifest
  def job(name)
    @manifest["jobs"].find { |job| job["name"] == name }
  end

  # find a specificly named resource pool in the manifest
  def resource_pool(name)
    @manifest["resource_pools"].find { |res| res["name"] == name }
  end

  describe "0 redis servers" do
    subject { Bosh::CloudFoundry::Config::RedisServiceConfig.build_from_system_config(@system_config) }
    it "has 0 redis servers" do
      subject.total_service_nodes_count.should == 0
    end
    it "is not in the core job" do
      subject.add_core_jobs_to_manifest(@manifest)
      job("core")["template"].should_not be_include("redis")
    end
    it "should not add a resoure pool called 'redis'" do
      subject.add_resource_pools_to_manifest(@manifest)
      @manifest["resource_pools"].size.should == 1
      resource_pool("redis").should be_nil
    end
    it "should not add a job called 'redis'" do
      subject.add_jobs_to_manifest(@manifest)
      @manifest["jobs"].size.should == 1
      job("redis").should be_nil
    end
    it "does not set properties.redis_gateway" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["redis_gateway"].should be_nil
    end
    it "does not set properties.redis_node" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["redis_node"].should be_nil
    end
    it "does not set properties.service_plans.redis" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["service_plans"]["redis"].should be_nil
    end
  end
  describe "1 x m1.xlarge redis node on AWS" do
    subject do
      @system_config.redis = [{ "count" => 1, "flavor" => 'm1.xlarge' }]
      Bosh::CloudFoundry::Config::RedisServiceConfig.build_from_system_config(@system_config)
    end
    it "has 1 redis servers" do
      subject.total_service_nodes_count.should == 1
    end
    it "does not add colocated job to core job" do
      subject.add_core_jobs_to_manifest(@manifest)
      job("core")["template"].should_not be_include("redis")
    end
    it "adds redis_gateway to core job" do
      subject.add_core_jobs_to_manifest(@manifest)
      job("core")["template"].should be_include("redis_gateway")
    end
    it "should add a resoure pool called 'redis'" do
      subject.add_resource_pools_to_manifest(@manifest)
      @manifest["resource_pools"].size.should == 2
      resource_pool("redis_m1_xlarge_free").should_not be_nil
      resource_pool("redis_m1_xlarge_free")["size"].should == 1
      resource_pool("redis_m1_xlarge_free")["cloud_properties"]["instance_type"].should == "m1.xlarge"
    end
    it "converts 1 redis into an explicit redis job" do
      subject.add_jobs_to_manifest(@manifest)
      job("redis_m1_xlarge_free").should_not be_nil
      job("redis_m1_xlarge_free")["template"].should == ["redis_node"]
      job("redis_m1_xlarge_free")["instances"].should == 1
    end
    it "sets properties.redis_gateway" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["redis_gateway"].should_not be_nil
    end
    it "sets properties.redis_node" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["redis_node"].should_not be_nil
    end
    it "sets properties.service_plans.redis" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["service_plans"]["redis"].should_not be_nil
    end
  end
end