require "bosh/cli/commands/cf"

describe Bosh::Cli::Command::CloudFoundry do
  include FileUtils

  let(:command) { Bosh::Cli::Command::CloudFoundry.new }

  before(:all) do
    # Let us have pretty access to all protected methods which are protected from the bosh_cli plugin system.
    Bosh::Cli::Command::CloudFoundry.send(:public, *Bosh::Cli::Command::CloudFoundry.protected_instance_methods)
  end

  before { setup_home_dir }

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
        release_yml = File.expand_path("../../bosh_release/releases/cf-release-132.yml", __FILE__)
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
      before do
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
        command.biff.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))

        deployment_cmd = mock("deployment_cmd")
        deployment_cmd.should_receive(:set_current).with(home_file("deployments/cf/demo.yml"))
        deployment_cmd.stub(:perform)
        command.stub(:deployment_cmd).and_return(deployment_cmd)
      end

      it "generates a medium deployment (medium is default size)" do
        in_home_dir do
          File.should_not be_exist(command.deployment_file)
          command.create_cf
          files_match(spec_asset("v132/aws/medium.yml"), command.deployment_file)

          manifest = YAML.load_file(command.deployment_file)
          Bosh::Cli::DeploymentManifest.new(manifest).normalize
        end
      end

      it "generates a large deployment" do
        in_home_dir do
          command.add_option(:deployment_size, "large")

          command.create_cf
          files_match(spec_asset("v132/aws/large.yml"), command.deployment_file)

          manifest = YAML.load_file(command.deployment_file)
          Bosh::Cli::DeploymentManifest.new(manifest).normalize
        end
      end

      it "specifies core size" do
        in_home_dir do
          command.add_option(:size, "xlarge")
          command.create_cf
        end
      end

      context "and show passwords" do
        it "displays the list of internal passwords" do
          in_home_dir do
            command.create_cf
            command.show_cf_passwords
          end
        end
      end

    end

  end

end