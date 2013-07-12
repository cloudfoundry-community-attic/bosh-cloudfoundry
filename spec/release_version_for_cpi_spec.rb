describe Bosh::Cloudfoundry::ReleaseVersionForCpi do
  subject { Bosh::Cloudfoundry::ReleaseVersionForCpi.for_cpi(132, "aws") }

  it "has available deployment sizes" do
    subject.available_deployment_sizes.should == %w[medium large]
  end

  it "has default deployment size" do
    subject.default_deployment_size.should == "medium"
  end
end