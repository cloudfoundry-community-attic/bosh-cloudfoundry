describe Bosh::Cloudfoundry::DeploymentFile do

  def initial_deployment_file(properties = {})
    FileUtils.mkdir_p("deployments/cf")
    file = home_file("deployments/cf/deployment.yml")
    File.open(file, "w") do |f|
      f << {
        "name" => "demo",
        "releases" => [
          {"name" => "cf-release", "version" => 132}
        ],
        "properties" => {
          "cf" => properties.merge({
            "dns" => "mycloud.com",
            "ip_addresses" => ['1.2.3.4'],
            "deployment_size" => "medium",
            "security_group" => "cf",
            "persistent_disk" => 4096,
            "common_passwords" => "qwerty"
          })
        }
      }.to_yaml
    end
    file
  end

  it "can reconstruct DeploymentFile from even minimal deployment file" do
    file = initial_deployment_file
    deployment_file = Bosh::Cloudfoundry::DeploymentFile.reconstruct_from_deployment_file(
      file, mock("director"), {"cpi" => "openstack"})

    # simple tests to check the values all went into the right places
    deployment_file.deployment_size.should == "medium"
    deployment_file.deployment_attributes.dns.should == "mycloud.com"
    deployment_file.bosh_cpi.should == "openstack"
    deployment_file.release_version_number.should == 132
  end

  context "generates deployment (aws)" do
    let(:bosh_cpi) { "aws" }
    let(:bosh_status) { {"cpi" => bosh_cpi, "uuid" => "UUID"} }
    let(:release_version_cpi) { Bosh::Cloudfoundry::ReleaseVersionCpi.latest_for_cpi(bosh_cpi) }
    let(:release_version_cpi_medium) { Bosh::Cloudfoundry::ReleaseVersionCpiSize.new(release_version_cpi, "medium") }
    let(:deployment_attributes) do
      Bosh::Cloudfoundry::DeploymentAttributes.new(mock("director"), bosh_status, release_version_cpi_medium, {
        name: "demo",
        dns: "mycloud.com",
        ip_addresses: ['1.2.3.4']
      })
    end

    subject { Bosh::Cloudfoundry::DeploymentFile.new(release_version_cpi_medium, deployment_attributes, bosh_status) }

    before do
      subject.biff.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))
      deployment_cmd = mock("deployment_cmd")
      deployment_cmd.stub(:set_current).with(home_file("deployments/cf/demo.yml"))
      deployment_cmd.stub(:perform)
      subject.stub(:deployment_cmd).and_return(deployment_cmd)
    end

    it "medium size" do
      in_home_dir do
        file = home_file("deployments/cf/demo.yml")
        subject.prepare_environment
        subject.create_deployment_file
        subject.deploy(non_interactive: true)
        manifest = YAML.load_file(file)
      end
    end
  # 
  # it "generates a large deployment" do
  #   in_home_dir do
  #     command.add_option(:deployment_size, "large")
  # 
  #     command.create_cf
  #     files_match(spec_asset("v132/aws/large.yml"), command.deployment_file)
  # 
  #     manifest = YAML.load_file(command.deployment_file)
  #     Bosh::Cli::DeploymentManifest.new(manifest).normalize
  #   end
  # end
  # 
  # it "specifies core size" do
  #   in_home_dir do
  #     command.add_option(:size, "xlarge")
  #     command.create_cf
  #   end
  # end

  end
end
