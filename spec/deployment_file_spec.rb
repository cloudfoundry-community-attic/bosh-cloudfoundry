describe Bosh::Cloudfoundry::DeploymentFile do
  # it "generates a medium deployment (medium is default size)" do
  #   in_home_dir do
  #     File.should_not be_exist(command.deployment_file)
  #     command.create_cf
  #     files_match(spec_asset("v132/aws/medium.yml"), command.deployment_file)
  # 
  #     manifest = YAML.load_file(command.deployment_file)
  #     Bosh::Cli::DeploymentManifest.new(manifest).normalize
  #   end
  # end
  # 
  # it "generates a large deployment" do
  #   in_home_dir do
  #     command.add_option(:deployment_size, "large")
  # 
  #     command.create_cf
  #     files_match(spec_asset("v132/aws/large.yml"), command.deployment_file)
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
# 
# command.biff.stub(:deployment).and_return(home_file("deployments/cf/demo.yml"))
# 
# deployment_cmd = mock("deployment_cmd")
# deployment_cmd.should_receive(:set_current).with(home_file("deployments/cf/demo.yml"))
# deployment_cmd.stub(:perform)
# command.stub(:deployment_cmd).and_return(deployment_cmd)
