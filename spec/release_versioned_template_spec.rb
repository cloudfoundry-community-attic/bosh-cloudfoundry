require "bosh/cloudfoundry/release_versioned_template"

describe Bosh::Cloudfoundry::ReleaseVersionedTemplate do
  subject { Bosh::Cloudfoundry::ReleaseVersionedTemplate.new(132, "aws", "dev") }
  it "path to template" do
    subject.template_file_path.should =~ %r{v132/aws/dev/deployment_file.yml.erb$}
  end

  it "path to template spec" do
    subject.spec_file_path.should =~ %r{v132/aws/dev/spec$}
  end
end