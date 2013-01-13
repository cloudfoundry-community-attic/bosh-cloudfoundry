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
  end
  describe "0 deas" do
    subject { Bosh::CloudFoundry::Config::DeaConfig.build_from_system_config(@system_config) }
    it "converted into a colocated dea on the core job" do
      subject.dea_server_count.should == 0
      subject.jobs_to_add_to_core_server.should == %w[dea]
    end
    it "sets the properties.dea.max_memory" do
      subject.deployment_manifest_properties.should == {
        "dea" => {
          "max_memory" => 512
        }
      }
    end
  end
  describe "5 x m1.xlarge deas on AWS" do
    subject do
      @system_config.dea = { count: 5, flavor: 'm1.xlarge' }
      Bosh::CloudFoundry::Config::DeaConfig.build_from_system_config(@system_config)
    end
    it "converts 1 dea into an explicit dea job" do
      subject.dea_server_count.should == 5
      subject.jobs_to_add_to_core_server.should == []
    end
    it "sets the properties.dea.max_memory for each m1.large server" do
      # m1.xlarge has 15G RAM
      subject.deployment_manifest_properties.should == {
        "dea" => {
          "max_memory" => 15060 # 15360 for an m1.xlarge minus 300 for the DEA & agent
        }
      }
    end
  end
end