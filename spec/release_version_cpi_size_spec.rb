describe Bosh::Cloudfoundry::ReleaseVersionCpiSize do
  let(:release_version_cpi) { Bosh::Cloudfoundry::ReleaseVersionCpi.for_cpi(132, "aws") }

  subject { Bosh::Cloudfoundry::ReleaseVersionCpiSize.new(release_version_cpi, "medium") }

  it "path to template" do
    subject.template_file_path.should =~ %r{v132/aws/medium/deployment_file.yml.erb$}
  end

  it "path to template spec" do
    subject.spec_file_path.should =~ %r{v132/aws/medium/spec$}
  end
end