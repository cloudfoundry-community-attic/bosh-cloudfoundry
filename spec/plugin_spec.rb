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

  context "create cf" do
    context "with requirements" do
      before do
        command.add_option(:config, home_file(".bosh_config"))
        command.add_option(:non_interactive, true)
        command.add_option(:name, "demo")
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:dns, "mycloud.com")

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

      it "generates a deployment file" do
        in_home_dir do
          File.should_not be_exist(command.deployment_file)
          command.create_cf
          File.should be_exist(command.deployment_file)
        end
      end

      it "generates deployment file with required keys" do
        in_home_dir do
          command.create_cf
          manifest = YAML.load_file(command.deployment_file)
          required_deployment_keys = %w[name director_uuid releases compilation update resource_pools jobs properties]
          required_deployment_keys.each do |required_key|
            manifest[required_key].should_not be_nil
          end
        end
      end

      it "generate deployment file that can be normalized" do
        in_home_dir do
          command.create_cf
          manifest = YAML.load_file(command.deployment_file)
          # invokes #err if any errors found
          Bosh::Cli::DeploymentManifest.new(manifest).normalize
        end
      end

      it "specifies core size" do
        in_home_dir do
          command.add_option(:size, "xlarge")
          command.create_cf
        end
      end
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
end