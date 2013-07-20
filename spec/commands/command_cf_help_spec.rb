require "bosh/cli/commands/99_cf_help"

describe Bosh::Cli::Command::CloudFoundryHelp do
  let(:command) { Bosh::Cli::Command::CloudFoundryHelp.new }

  it "shows help" do
    command.cf_help
  end
end
