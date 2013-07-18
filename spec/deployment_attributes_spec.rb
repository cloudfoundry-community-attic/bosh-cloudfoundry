describe Bosh::Cloudfoundry::DeploymentAttributes do
  context "default value" do
    let(:director) { mock("director") }
    let(:bosh_status) { {"cpi" => "aws", "uuid" => "uuid"} }
    let(:release_version_cpi) { instance_double(Bosh::Cloudfoundry::ReleaseVersionCpi)}
    subject { Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi) }
    it { subject.deployment_size.should == "medium" }
    it { subject.persistent_disk.should == 4096 }
    it { subject.security_group.should == "default" }
    it { subject.common_password.size.should == 12 }
  end
end