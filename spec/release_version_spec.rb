describe Bosh::Cloudfoundry::ReleaseVersion do
  it "cannot accept versions lower than 132" do
    expect { Bosh::Cloudfoundry::ReleaseVersion.for_version(131) }.to raise_error(RuntimeError)
  end

  it "finds an exact version match" do
    Bosh::Cloudfoundry::ReleaseVersion.for_version(132).version_number.should == 132
  end

  it "finds an next available version match" do
    Bosh::Cloudfoundry::ReleaseVersion.for_version(200).version_number.should == latest_cf_release_version
  end

  it "knows available versions" do
    Bosh::Cloudfoundry::ReleaseVersion.available_versions.should == [132, 133, 134, 136, 141, 146, 149,150, 151, 168]
  end

  it "knows latest version number" do
    Bosh::Cloudfoundry::ReleaseVersion.latest_version_number.should == latest_cf_release_version
  end

  context "for v132" do
    subject { Bosh::Cloudfoundry::ReleaseVersion.for_version(132) }

    it "loads available CPIs" do
      subject.available_cpi_names.sort.should == %w[aws openstack]
    end

    it "has valid CPIs" do
      subject.valid_cpi?("aws").should be_true
      subject.valid_cpi?("openstack").should be_true
    end

    it "has invalid CPIs" do
      subject.valid_cpi?("xyz").should be_false
    end
  end
end
