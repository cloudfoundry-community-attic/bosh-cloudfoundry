# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../../spec_helper", __FILE__)

# The specification of how a user's DEA choices (count & flavor)
# are converted into deployment manifest configuration
describe Bosh::CloudFoundry::Config::DeaConfig do
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

  describe "0 deas" do
    subject { Bosh::CloudFoundry::Config::DeaConfig.build_from_system_config(@system_config) }
    it "has 0 dea servers" do
      subject.dea_server_count.should == 0
    end
    it "converted into a colocated dea on the core job" do
      subject.add_core_jobs_to_manifest(@manifest)
      job("core")["template"].should be_include("dea")
    end
    it "should not add a resoure pool called 'dea'" do
      subject.add_resource_pools_to_manifest(@manifest)
      @manifest["resource_pools"].size.should == 1
    end
    it "should not add a job called 'dea'" do
      subject.add_jobs_to_manifest(@manifest)
      @manifest["jobs"].size.should == 1
      job("dea").should be_nil
    end
    it "sets the properties.dea.max_memory" do
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["dea"].should_not be_nil
      @manifest["properties"]["dea"]["max_memory"].should_not be_nil
      @manifest["properties"]["dea"]["max_memory"].should == 512
    end
  end
  describe "5 x m1.xlarge deas on AWS" do
    subject do
      @system_config.dea = { "count" => 5, "flavor" => 'm1.xlarge' }
      Bosh::CloudFoundry::Config::DeaConfig.build_from_system_config(@system_config)
    end
    it "has 5 dea servers" do
      subject.dea_server_count.should == 5
    end
    it "has dea servers of flavor 'm1.xlarge'" do
      subject.dea_server_flavor.should == 'm1.xlarge'
    end
    it "does not add colocated job to core job" do
      subject.add_core_jobs_to_manifest(@manifest)
      job("core").should_not be_include("dea")
    end
    it "should add a resoure pool called 'dea'" do
      subject.add_resource_pools_to_manifest(@manifest)
      @manifest["resource_pools"].size.should == 2
      resource_pool("dea").should_not be_nil
      resource_pool("dea")["size"].should == 5
      resource_pool("dea")["cloud_properties"]["instance_type"].should == "m1.xlarge"
    end
    it "converts 1 dea into an explicit dea job" do
      subject.add_jobs_to_manifest(@manifest)
      job("dea").should_not be_nil
      job("dea")["template"].should == ["dea"]
      job("dea")["instances"].should == 5
    end
    it "sets the properties.dea.max_memory for each m1.xlarge server" do
      Bosh::CloudFoundry::Providers.should_receive(:for_bosh_provider_name).
        and_return(Bosh::CloudFoundry::Providers::AWS.new)
      # m1.xlarge has 15G RAM
      subject.merge_manifest_properties(@manifest)
      @manifest["properties"]["dea"].should_not be_nil
      @manifest["properties"]["dea"]["max_memory"].should_not be_nil
      @manifest["properties"]["dea"]["max_memory"].should == 15060
    end
  end
end