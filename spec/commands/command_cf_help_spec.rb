require "bosh/cli/commands/99_cf_help"

describe Bosh::Cli::Command::CloudFoundryHelp do
  let(:command) { Bosh::Cli::Command::CloudFoundryHelp.new }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
  end

  it "shows help" do
    command.cf_help
  end
end
