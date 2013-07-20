require "bosh/cli/commands/02_create_cf"

describe Bosh::Cli::Command::CloudFoundry do
  include FileUtils

  let(:command) { Bosh::Cli::Command::CloudFoundry.new }
  let(:director) { instance_double("Bosh::Cli::Director") }

  def setup_deployment
    deployment_file = home_file("deployment.yml")
    command.stub(:deployment).and_return(deployment_file)
    File.open(deployment_file, "w") do |f|
      f << {
        "releases" => [
          {"name" => "cf-release", "version" => 132}
        ],
        "properties" => {
          "cf" => {
            # immutable attributes (determined via ReleaseVersion via templates/vXYZ/spec)
            "name" => "demo",
            "deployment_size" => "medium",
            "dns" => "mycloud.com",
            "common_password" => "qwerty",
            # mutable attributes (determined via ReleaseVersion via templates/vXYZ/spec)
            "ip_addresses" => ["1.2.3.4"],
            "persistent_disk" => 4096,
            "security_group" => "cf"
          }
        }
      }.to_yaml
    end
    deployment_file
  end

  before(:all) do
    # Let us have pretty access to all protected methods which are protected from the bosh_cli plugin system.
    Bosh::Cli::Command::CloudFoundry.send(:public, *Bosh::Cli::Command::CloudFoundry.protected_instance_methods)
  end

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
  end

  context "create cf" do
    context "validation failures" do
      before do
        director.stub(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
        command.stub(:director).and_return(director)
      end
      it "requires --ip 1.2.3.4" do
        command.add_option(:dns, "mycloud.com")
        command.add_option(:size, "xlarge")
        expect { command.create_cf }.to raise_error(Bosh::Cli::CliError)
      end

      it "requires --dns" do
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:size, "xlarge")
        expect { command.create_cf }.to raise_error(Bosh::Cli::CliError)
      end
    end

    context "with requirements" do
      it "creates cf deployment" do
        command.add_option(:name, "demo")
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:dns, "mycloud.com")
        command.add_option(:common_password, "qwertyasdfgh")

        command.should_receive(:auth_required)
        command.should_receive(:validate_deployment_attributes)

        director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
        command.stub(:director).and_return(director)

        command.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))

        deployment_file = instance_double("Bosh::Cloudfoundry::DeploymentFile")
        Bosh::Cloudfoundry::DeploymentFile.should_receive(:new).
          and_return(deployment_file)
        deployment_file.should_receive(:perform)

        command.create_cf
      end

    end
  end
  
  context "existing deployment" do
    before do
      @deployment_file_path = setup_deployment

      director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
      command.stub(:director).and_return(director)
    end

    it "displays the list of attributes/properties" do
      command.show_cf_attributes
    end

    context "modifies attributes/properties and redeploys" do
      let(:deployment_attributes) { instance_double("Bosh::Cloudfoundry::DeploymentAttributes")}
      before do
        deployment_file = instance_double("Bosh::Cloudfoundry::DeploymentFile")
        Bosh::Cloudfoundry::DeploymentFile.should_receive(:new).
          and_return(deployment_file)
        deployment_file.should_receive(:deployment_attributes).and_return(deployment_attributes)
        deployment_file.should_receive(:release_version_cpi_size)
        deployment_file.should_receive(:perform)

        command.should_receive(:validate_deployment_attributes)

        deployment_attributes.stub(:mutable_attributes).and_return([:persistent_disk, :security_group])
      end

      it "for single property" do
        deployment_attributes.should_receive(:validated_color).with("persistent_disk")
        deployment_attributes.should_receive(:mutable_attribute?).with("persistent_disk").and_return(true)
        deployment_attributes.should_receive(:set_mutable).with("persistent_disk", "8192")

        command.change_cf_attributes("persistent_disk=8192")
      end

      it "for multiple properties" do
        deployment_attributes.should_receive(:validated_color).with("persistent_disk")
        deployment_attributes.should_receive(:validated_color).with("security_group")
        deployment_attributes.should_receive(:mutable_attribute?).with("persistent_disk").and_return(true)
        deployment_attributes.should_receive(:mutable_attribute?).with("security_group").and_return(true)
        deployment_attributes.should_receive(:set_mutable).with("persistent_disk", "8192")
        deployment_attributes.should_receive(:set_mutable).with("security_group", "cf-core")

        command.change_cf_attributes("persistent_disk=8192", "security_group=cf-core")
      end
    end
  end
end