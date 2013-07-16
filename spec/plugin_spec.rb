require "bosh/cli/commands/cf"
require "fakeweb"

describe Bosh::Cli::Command::CloudFoundry do
  include FileUtils

  let(:command) { Bosh::Cli::Command::CloudFoundry.new }

  before(:all) do
    # Let us have pretty access to all protected methods which are protected from the bosh_cli plugin system.
    Bosh::Cli::Command::CloudFoundry.send(:public, *Bosh::Cli::Command::CloudFoundry.protected_instance_methods)
  end

  before { setup_home_dir }
  before { FakeWeb.allow_net_connect = false }

  it "shows help" do
    subject.cf_help
  end

  context "prepare cf" do
    before do
      command.add_option(:config, home_file(".bosh_config"))
      command.add_option(:non_interactive, true)
      command.should_receive(:auth_required)
    end

    context "director does not already have release" do
      it "upload release" do
        release_yml = File.expand_path("../../bosh_release/releases/cf-release-133.yml", __FILE__)
        release_cmd = mock("release_cmd")
        release_cmd.should_receive(:upload).with(release_yml)
        command.stub(:release_cmd).and_return(release_cmd)

        command.prepare_cf
      end
    end

    context "director already has release" do
      it "do not upload"
    end
  end

  context "create cf" do
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

    context "with requirements" do
      it "creates cf deployment" do
        command.add_option(:config, home_file(".bosh_config"))
        command.add_option(:non_interactive, true)
        command.add_option(:name, "demo")
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:dns, "mycloud.com")
        command.add_option(:common_password, "qwertyasdfgh")

        command.should_receive(:auth_required)

        director = mock("director_client")
        director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
        command.stub(:director_client).and_return(director)

        command.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))

        deployment_file = mock("deployment_file")
        Bosh::Cloudfoundry::DeploymentFile.should_receive(:new).
          and_return(deployment_file)
        deployment_file.should_receive(:prepare_environment)
        deployment_file.should_receive(:create_deployment_file)
        deployment_file.should_receive(:deploy)

        command.create_cf
      end

    end

    it "displays the list of internal passwords" do
      command.add_option(:config, home_file(".bosh_config"))
      command.add_option(:non_interactive, true)

      director = mock("director_client")
      director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
      command.stub(:director_client).and_return(director)

      command.stub(:deployment).and_return(home_file("deployment.yml"))
      File.open(home_file("deployment.yml"), "w") do |f|
        f << {
          "releases" => [
            {"name" => "cf-release", "version" => 132}
          ],
          "properties" => {
            "cf" => {
              "common_passwords" => "qwerty"
            }
          }
        }.to_yaml
      end
      command.show_cf_passwords
    end
  end

end