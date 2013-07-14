describe Bosh::Cloudfoundry::ReleaseVersionCpiSize do
  subject { Bosh::Cloudfoundry::ReleaseVersionCpiSize.for_deployment_size(132, "aws", "medium") }
  it "path to template" do
    subject.template_file_path.should =~ %r{v132/aws/medium/deployment_file.yml.erb$}
  end

  it "path to template spec" do
    subject.spec_file_path.should =~ %r{v132/aws/medium/spec$}
  end
end