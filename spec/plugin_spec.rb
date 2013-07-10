require "bosh/cli/commands/cf"

describe Bosh::Cli::Command::CloudFoundry do
  let(:command) { Bosh::Cli::Command::CloudFoundry.new }

  it "shows help" do
    subject.cf_help
  end

  context "create cf" do
    context "with requirements" do
      before do
        command.add_option(:ip, ["1.2.3.4"])
        command.add_option(:dns, "mycloud.com")
      end

      it "provides default values" do
        command.create_cf
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