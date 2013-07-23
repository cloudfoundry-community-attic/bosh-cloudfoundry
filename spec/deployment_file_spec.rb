describe Bosh::Cloudfoundry::DeploymentFile do
  def initial_deployment_file(properties = {})
    FileUtils.mkdir_p(home_file("deployments/cf"))
    file = home_file("deployments/cf/demo.yml")
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
            "common_passwords" => "qwertyasdfgh"
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

  # aws & openstack
  # v132 & v133
  # medium & large

  %w[medium large].each do |deployment_size|
    context "generates deployment (aws)" do
      let(:bosh_cpi) { "aws" }
      let(:bosh_status) { {"cpi" => bosh_cpi, "uuid" => "UUID"} }
      let(:attributes) { {
        name: "demo",
        dns: "mycloud.com",
        ip_addresses: ['1.2.3.4'],
        common_password: "qwertyasdfgh",
        deployment_size: deployment_size
      } }
      let(:release_version_cpi) { Bosh::Cloudfoundry::ReleaseVersionCpi.for_cpi(133, bosh_cpi) }
      let(:release_version_cpi_size) { Bosh::Cloudfoundry::ReleaseVersionCpiSize.new(release_version_cpi, deployment_size) }
      let(:deployment_attributes) do
        Bosh::Cloudfoundry::DeploymentAttributes.new(mock("director"), bosh_status, release_version_cpi_size, attributes)
      end

      subject { Bosh::Cloudfoundry::DeploymentFile.new(release_version_cpi_size, deployment_attributes, bosh_status) }

      before do
        subject.biff.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))
        deployment_cmd = mock("deployment_cmd")
        deployment_cmd.stub(:set_current).with(home_file("deployments/cf/demo.yml"))
        deployment_cmd.stub(:perform)
        subject.stub(:deployment_cmd).and_return(deployment_cmd)
      end

      it "#{deployment_size} size" do
        in_home_dir do
          subject.prepare_environment

          subject.create_deployment_file
          files_match(spec_asset("v133/aws/#{deployment_size}.yml"), subject.deployment_file)

          subject.deploy(non_interactive: true)
        end
      end
    end
    # it "large size" do
    #   in_home_dir do
    #     command.add_option(:deployment_size, "large")
    # 
    #     command.create_cf
    #     files_match(spec_asset("v133/aws/large.yml"), command.deployment_file)
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
