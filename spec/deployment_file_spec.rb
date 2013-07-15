describe Bosh::Cloudfoundry::DeploymentFile do
  it "can reconstruct DeploymentFile from even minimal deployment file" do
    file = home_file("deployment.yml")
    File.open(file, "w") do |f|
      f << {
        "releases" => [
          {"name" => "cf-release", "version" => 132}
        ],
        "properties" => {
          "cf" => {
            "dns" => "mycloud.com",
            "ip_addresses" => ['1.2.3.4'],
            "deployment_size" => "medium",
            "security_group" => "cf",
            "persistent_disk" => 4096,
            "common_passwords" => "qwerty"
          }
        }
      }.to_yaml
    end
    deployment_file = Bosh::Cloudfoundry::DeploymentFile.reconstruct_from_deployment_file(
      file, mock("director"), {"cpi" => "openstack"})

    deployment_file.deployment_size.should == "medium"
    deployment_file.deployment_attributes.dns.should == "mycloud.com"
    deployment_file.bosh_cpi.should == "openstack"
    deployment_file.release_version_number.should == 132
  end
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
