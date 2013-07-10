require "bosh/cli/commands/cf"

describe Bosh::Cli::Command::CloudFoundry do
  include FileUtils

  let(:command) { Bosh::Cli::Command::CloudFoundry.new }

  it "shows help" do
    subject.cf_help
  end

  # create files in a safe place
  # before { chdir(home_file("")) }
  context "create cf" do
    context "with requirements" do
      before do
        command.add_option(:config, home_file(".bosh_config"))
        command.add_option(:non_interactive, true)
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:dns, "mycloud.com")
        command.should_receive(:auth_required)
        director = mock("director_client")
        director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
        command.stub(:director_client).and_return(director)
      end

      it "generates a deployment file" do
        command.deployment.should be_nil
        command.create_cf
        command.deployment.should_not be_nil
      end

      it "generates deployment file with required keys" do
        command.create_cf
        manifest = YAML.load_file(command.deployment)
        required_deployment_keys = %w[name description release compilation update resource_pools jobs properties]
        required_deployment_keys.each do |required_key|
          manifest[required_key].should_not be_nil
        end
      end

      it "generate deployment file that can be normalized" do
        command.create_cf
        manifest = YAML.load_file(command.deployment)
        # invokes #err if any errors found
        Bosh::Cli::DeploymentManifest.new(manifest).normalize
      end

      it "specifies core size" do
        command.add_option(:size, "xlarge")
        command.create_cf
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