require "bosh/cli/commands/01_prepare_bosh_for_cf"

describe Bosh::Cli::Command::PrepareBoshForCloudFoundry do
  let(:command) { Bosh::Cli::Command::PrepareBoshForCloudFoundry.new }
  let(:director) { instance_double("Bosh::Cli::Director") }
  let(:latest_release_version_number) { 133 }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
  end

  context "prepare cf" do
    before do
      command.should_receive(:auth_required)

      director.should_receive(:get_status).and_return({"uuid" => "UUID", "cpi" => "aws"})
      command.stub(:director).and_return(director)
    end

    it "upload release if bosh does not already have release" do
      release_yml = File.expand_path("../../../bosh_release/releases/cf-release-#{latest_release_version_number}.yml", __FILE__)
      release_cmd = instance_double("Bosh::Cli::Command::Release")
      release_cmd.should_receive(:upload).with(release_yml)
      command.stub(:release_cmd).and_return(release_cmd)

      aws_full_stemcell_url = "http://bosh-jenkins-artifacts.s3.amazonaws.com/bosh-stemcell/aws/latest-bosh-stemcell-aws.tgz"
      stemcell_cmd = instance_double("Bosh::Cli::Command::Stemcell")
      stemcell_cmd.should_receive(:upload).with(aws_full_stemcell_url)
      command.stub(:stemcell_cmd).and_return(stemcell_cmd)

      command.prepare_cf
    end

    it "upload specific release"

    it "errors if specific requested release does not exist"

    it "errors if specific requested release is not enabled"

    it "do not upload release if bosh already has that release"

    it "do not upload stemcell if bosh already has stemcell"
  end

end
