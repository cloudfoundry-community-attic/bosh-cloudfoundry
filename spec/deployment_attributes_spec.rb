describe Bosh::Cloudfoundry::DeploymentAttributes do
  let(:director) { instance_double("Bosh::Cli::Director") }
  let(:bosh_status) { {"cpi" => "aws", "uuid" => "uuid"} }
  let(:release_version_cpi) { instance_double("Bosh::Cloudfoundry::ReleaseVersionCpi")}

  before { SecureRandom.stub(:hex).and_return("qwertyqwerty") }

  context "default value" do
    subject { Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi) }
    it { subject.deployment_size.should == "medium" }
    it { subject.persistent_disk.should == 4096 }
    it { subject.security_group.should == "default" }
    it { subject.common_password.should == "qwertyqwerty" }
  end

  context "attributes" do
    it "returns default attributes" do
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi)
      subject.available_attributes.sort.should ==
        %w[common_password deployment_size name persistent_disk security_group].map(&:to_sym)
    end

    it "returns additional attributes" do
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi, {
        dns: "mycloud.com", ip_addresses: ["1.2.3.4"]
      })
      subject.available_attributes.sort.should ==
        %w[common_password deployment_size dns ip_addresses name persistent_disk security_group].map(&:to_sym)
    end

    # immutable_attributes ultimately determined by ReleaseVersion (from templates/vXYZ/spec)
    it "immutable_attributes derived from release_version[_cpi]" do
      immutable_attributes = %w[common_password deployment_size dns name].map(&:to_sym)
      release_version_cpi.should_receive(:immutable_attributes).and_return(immutable_attributes)
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi, {
        dns: "mycloud.com", ip_addresses: ["1.2.3.4"]
      })
      subject.immutable_attributes.should == immutable_attributes
    end

    # mutable_attributes ultimately determined by ReleaseVersion (from templates/vXYZ/spec)
    it "mutable_attributes derived from release_version[_cpi]" do
      mutable_attributes = %w[ip_addresses persistent_disk security_group].map(&:to_sym)
      release_version_cpi.should_receive(:mutable_attributes).and_return(mutable_attributes)
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi, {
        dns: "mycloud.com", ip_addresses: ["1.2.3.4"]
      })
      subject.mutable_attributes.should == mutable_attributes
    end
  end
end