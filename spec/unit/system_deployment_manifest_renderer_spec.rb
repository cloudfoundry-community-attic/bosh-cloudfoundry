# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::CloudFoundry::SystemDeploymentManifestRenderer do
  before(:each) do
    @dir = Dir.mktmpdir("system_config_spec")
    @config = Bosh::CloudFoundry::SystemConfig.new(@dir)
  end

  after(:each) do
    FileUtils.remove_entry_secure @dir
  end

  describe "rendering deployment manifest(s)" do
    it "renders a micro system into a deployment manifest"
    it "renders a simple system + postgresql into a deployment manifest"
    it "renders a simple system + postgresql + redis into a deployment manifest"
  end
end
