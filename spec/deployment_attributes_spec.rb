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
    it { subject.dea_server_ram.should == 1500 }
  end

  context "delayed default values" do
    subject { Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi) }
    it "dns nil default until ip_addresses set" do
      subject.dns.should be_nil
    end

    it "dns defaults to FIRST_IP_ADDRESS.xip.io if ip_addresses has 1+ addresses" do
      subject.set(:ip_addresses, ["1.2.3.4"])
      subject.dns.should == "1.2.3.4.xip.io"
    end

    it "dns has custom value if set" do
      subject.set(:ip_addresses, ["1.2.3.4"])
      subject.set(:dns, "mycloud.com")
      subject.dns.should == "mycloud.com"
    end
  end

  context "attributes" do
    it "returns default attributes" do
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi)
      subject.available_attributes.sort.should ==
        %w[common_password dea_server_ram deployment_size name persistent_disk security_group skip_dns_validation].map(&:to_sym)
    end

    it "returns additional attributes" do
      subject = Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi, {
        dns: "mycloud.com", ip_addresses: ["1.2.3.4"]
      })
      subject.available_attributes.sort.should ==
        %w[common_password dea_server_ram deployment_size dns ip_addresses name persistent_disk security_group skip_dns_validation].map(&:to_sym)
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

    context "mutable attributes" do
      let(:mutable_attributes) { %w[dea_server_ram ip_addresses persistent_disk security_group].map(&:to_sym) }
      before { release_version_cpi.should_receive(:mutable_attributes).and_return(mutable_attributes) }

      subject do
        Bosh::Cloudfoundry::DeploymentAttributes.new(director, bosh_status, release_version_cpi, {
          dns: "mycloud.com", ip_addresses: ["1.2.3.4"]
        })
      end

      # mutable_attributes ultimately determined by ReleaseVersion (from templates/vXYZ/spec)
      it "mutable_attributes derived from release_version[_cpi]" do
        subject.mutable_attributes.should == mutable_attributes
      end

      it "mutable_attribute? is true for mutable attributes" do
        subject.should be_mutable_attribute("persistent_disk")
      end

      it "mutable_attribute? is false for immutable attributes" do
        subject.should_not be_mutable_attribute("name")
      end
    end
  end
end
