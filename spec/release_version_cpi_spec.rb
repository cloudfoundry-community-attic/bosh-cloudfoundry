describe Bosh::Cloudfoundry::ReleaseVersionCpi do
  let(:latest_release_version_number) { 134 }

  subject { Bosh::Cloudfoundry::ReleaseVersionCpi.for_cpi(133, "aws") }

  it "has available deployment sizes" do
    subject.available_deployment_sizes.should == %w[medium large]
  end

  it "has default deployment size" do
    subject.default_deployment_size.should == "medium"
  end

  it "latest_for_cpi(bosh_cpi)" do
    rvc = Bosh::Cloudfoundry::ReleaseVersionCpi.latest_for_cpi("aws")
    rvc.cpi.should == "aws"
    rvc.release_version_number.should == latest_release_version_number
  end
end