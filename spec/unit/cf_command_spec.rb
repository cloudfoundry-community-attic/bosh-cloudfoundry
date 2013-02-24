# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::Cli::Command::Base do
  include FileUtils

  before :each do
    @config = File.join(Dir.mktmpdir, "bosh_config")
    @common_config = File.join(Dir.mktmpdir, "bosh_common_config")
    @cache = File.join(Dir.mktmpdir, "bosh_cache")
    @systems_dir = File.join(Dir.mktmpdir, "systems")
    @releases_dir = File.join(Dir.mktmpdir, "releases")
    @stemcells_dir = File.join(Dir.mktmpdir, "stemcells")
    @repos_dir = File.join(Dir.mktmpdir, "repos")
    FileUtils.mkdir_p(@systems_dir)
    FileUtils.mkdir_p(@releases_dir)
    FileUtils.mkdir_p(@stemcells_dir)
    FileUtils.mkdir_p(@repos_dir)
  end

  describe Bosh::Cli::Command::CloudFoundry do

    before :each do
      @cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
      @cmd.add_option(:non_interactive, true)
      @cmd.add_option(:config, @config)
      @cmd.add_option(:common_config, @common_config)
      @cmd.add_option(:cache_dir, @cache)
      @cmd.add_option(:base_systems_dir, @systems_dir)
    end

    it "sets/gets the target system" do
      @cmd.system.should be_nil
      FileUtils.mkdir_p(File.join(@systems_dir, "production"))
      @cmd.set_system("production")
      File.basename(@cmd.system).should == "production"
      File.should be_directory(@cmd.system)
    end

    it "downloads stemcell and uploads it" do
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.stub!(:bosh_target_uuid).and_return("DIRECTOR_UUID")
      @cmd.stub!(:bosh_cpi).and_return("aws")
      @cmd.should_receive(:`).
        with("bosh public stemcells --tags aws | grep ' bosh-stemcell-' | awk '{ print $2 }' | sort -r | head -n 1").
        and_return("bosh-stemcell-aws-0.6.7.tgz")
      # FIXME default to stable stemcells when 0.8.1 is marked stable
      # @cmd.should_receive(:`).
      #   with("bosh public stemcells --tags aws,stable | grep ' bosh-stemcell-' | awk '{ print $2 }' | sort -r | head -n 1").
      #   and_return("bosh-stemcell-aws-0.6.7.tgz")
      @cmd.should_receive(:sh).
        with("bosh -n --color download public stemcell bosh-stemcell-aws-0.6.7.tgz")
      @cmd.should_receive(:sh).
        with("bosh -n --color upload stemcell #{@stemcells_dir}/bosh-stemcell-aws-0.6.7.tgz")

      @cmd.add_option(:stemcells_dir, @stemcells_dir)
      @cmd.add_option(:repos_dir, @repos_dir)
      @cmd.upload_stemcell
    end

    it "creates bosh stemcell and uploads it" do
      mkdir_p(File.join(@repos_dir, "bosh", "agent"))
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.stub!(:bosh_target_uuid).and_return("DIRECTOR_UUID")
      @cmd.stub!(:bosh_cpi).and_return("aws")
      @cmd.should_receive(:sh).with("git pull origin master")
      @cmd.should_receive(:sh).with("bundle install --without development test")
      @cmd.should_receive(:sh).with("sudo bundle exec rake stemcell:basic['aws']")
      @cmd.should_receive(:sh).with("sudo chown -R vcap:vcap /var/tmp/bosh/agent-*")
      @cmd.should_receive(:validate_stemcell_created_successfully)
      @cmd.should_receive(:move_and_return_created_stemcell).
        and_return(File.join(@stemcells_dir, "bosh-stemcell-aws-0.6.7.tgz"))
      @cmd.should_receive(:sh).
        with("bosh -n --color upload stemcell #{@stemcells_dir}/bosh-stemcell-aws-0.6.7.tgz")

      @cmd.add_option(:stemcells_dir, @stemcells_dir)
      @cmd.add_option(:repos_dir, @repos_dir)
      @cmd.add_option(:custom, true)
      @cmd.upload_stemcell
    end

    it "updates/creates/uploads final cf-release" do
      generate_new_system

      cf_release_dir = File.join(@releases_dir, "cf-release")
      @cmd.system_config.cf_release_dir = cf_release_dir
      @cmd.system_config.cf_release_branch = "master"
      @cmd.system_config.cf_release_branch_dir = File.join(cf_release_dir, "master")
      FileUtils.mkdir_p(@cmd.system_config.cf_release_branch_dir)
    
      @cmd.should_receive(:sh).with("git pull origin master")
      script = <<-BASH.gsub(/^      /, '')
      grep -rI "github.com" * .gitmodules | awk 'BEGIN {FS=":"} { print($1) }' | uniq while read file
      do
        echo "changing - $file"
        sed -i 's#git://github.com#https://github.com#g' $file
        sed -i 's#git@github.com:#https://github.com:#g' $file
      done
      BASH
      @cmd.should_receive(:sh).with("sed -i 's#git@github.com:#https://github.com/#g' .gitmodules")
      @cmd.should_receive(:sh).with("sed -i 's#git://github.com#https://github.com#g' .gitmodules")
      @cmd.should_receive(:sh).with("git submodule update --init --recursive")
      @cmd.should_receive(:`).with("tail -n 1 releases/index.yml | awk '{print $2}'").
        and_return("126")
      @cmd.should_receive(:sh).with("bosh -n --color upload release releases/appcloud-126.yml")
      @cmd.add_option(:final, true)
      @cmd.upload_release
    end

    it "updates/creates/uploads development/edge cf-release (requires system setup)" do
      generate_new_system

      cf_release_dir = File.join(@releases_dir, "cf-release")
      @cmd.system_config.cf_release_dir = cf_release_dir
      @cmd.system_config.cf_release_branch = "master"
      @cmd.system_config.cf_release_branch_dir = File.join(cf_release_dir, "master")
      FileUtils.mkdir_p(@cmd.system_config.cf_release_branch_dir)

      @cmd.add_option(:branch, "master")
    
      @cmd.should_receive(:sh).with("git pull origin master")
      script = <<-BASH.gsub(/^      /, '')
      grep -rI "github.com" * .gitmodules | awk 'BEGIN {FS=":"} { print($1) }' | uniq while read file
      do
        echo "changing - $file"
        sed -i 's#git://github.com#https://github.com#g' $file
        sed -i 's#git@github.com:#https://github.com:#g' $file
      done
      BASH
      @cmd.should_receive(:sh).with("sed -i 's#git@github.com:#https://github.com/#g' .gitmodules")
      @cmd.should_receive(:sh).with("sed -i 's#git://github.com#https://github.com#g' .gitmodules")
      @cmd.should_receive(:sh).with("git submodule update --init --recursive")
      @cmd.should_receive(:write_dev_config_file).with("appcloud-master")
      @cmd.should_receive(:sh).with("bosh -n --color create release --with-tarball --force")
      @cmd.should_receive(:sh).with("bosh -n --color upload release")
      @cmd.upload_release
    end

    def generate_new_system(cmd = nil)
      needs_initial_release_uploaded = true
      cmd ||= begin
        cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
        cmd.add_option(:non_interactive, true)
        cmd.add_option(:config, @config)
        cmd.add_option(:common_config, @common_config)
        cmd.add_option(:cache_dir, @cache)
        cmd.add_option(:base_systems_dir, @systems_dir)
        cmd
      end

      cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      cmd.stub!(:bosh_target_uuid).and_return("DIRECTOR_UUID")
      cmd.stub!(:bosh_cpi).and_return("aws")
      cmd.should_receive(:generate_common_password).and_return('c1oudc0wc1oudc0w')
      cmd.should_receive(:validate_dns_a_record).with("api.mycompany.com", '1.2.3.4').and_return(true)
      cmd.should_receive(:validate_dns_a_record).with("demoapp.mycompany.com", '1.2.3.4').and_return(true)

      if needs_initial_release_uploaded
        cmd.should_receive(:bosh_releases).exactly(1).times.and_return([])
        cmd.should_receive(:clone_or_update_cf_release)
        cmd.should_receive(:upload_final_release)
      else
        cmd.should_receive(:bosh_releases).exactly(1).times.and_return([
          {"name"=>"appcloud", "versions"=>["124", "126", "129"], "in_use"=>[]},
          {"name"=>"appcloud-master", "versions"=>["124.1-dev", "126.1-dev"], "in_use"=>[]},
        ])
      end

      cmd.should_receive(:bosh_stemcell_versions).exactly(4).times.and_return(['0.6.4'])
      cmd.should_receive(:render_system)

      provider = Bosh::CloudFoundry::Providers::AWS.new
      ports = {
        ssh: 22, http: 80, https: 433,
        postgres: 2544, resque: 3456,
        nats: 4222, router: 8080, uaa: 8100
      }
      provider.should_receive(:create_security_group).with("cloudfoundry-production", ports)
      Bosh::CloudFoundry::Providers.should_receive(:for_bosh_provider_name).and_return(provider)

      cmd.add_option(:core_ip, '1.2.3.4')
      cmd.add_option(:root_dns, 'mycompany.com')
      # cmd.add_option(:cf_release, 'appcloud')
      cmd.add_option(:core_server_flavor, 'm1.large')
      cmd.add_option(:admin_emails, ['drnic@starkandwayne.com'])

      cmd.common_config.releases_dir = @releases_dir
      cmd.common_config.stemcells_dir = @stemcells_dir

      cmd.system.should be_nil
      cmd.prepare_system("production")

      # expected from generate_new_system via Command#render_system
      mkdir_p(File.join(cmd.system, "deployments"))
    end

    it "creates new system" do
      generate_new_system(@cmd)
      File.basename(@cmd.system).should == "production"
    end

    it "uploads latest stemcell & final cf-release by default" do
      generate_new_system(@cmd)
      File.basename(@cmd.system).should == "production"
      @cmd.system_config.release_name.should == "appcloud"
    end

    it "new system has common random password" do
      generate_new_system(@cmd)
      @cmd.system_config.common_password.should == "c1oudc0wc1oudc0w"
    end

    it "sets 3 x m1.large dea server" do
      generate_new_system

      @cmd.should_receive(:render_system)

      @cmd.stub!(:bosh_cpi).and_return("aws")
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:flavor, 'm1.xlarge')
      @cmd.change_deas(3)

      @cmd.system_config.dea.should == { "count" => 3, "flavor" => 'm1.xlarge' }
    end

    it "fails for unknown service" do
      generate_new_system
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      expect {
        @cmd.add_service_node("UNKNOWN")
      }.to raise_error(Bosh::Cli::CliError)
    end

    it "add 4 postgresql nodes" do
      generate_new_system

      @cmd.should_receive(:render_system)

      @cmd.stub!(:bosh_cpi).and_return("aws")
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:flavor, 'm1.large')
      @cmd.add_service_node("postgresql", 4)

      @cmd.system_config.postgresql.size.should == 1
      postgresql_config = @cmd.system_config.postgresql.first
      postgresql_config["flavor"].should == "m1.large"
      postgresql_config["count"].should == 4
    end

    it "add 2 redis nodes" do
      generate_new_system
    
      @cmd.should_receive(:render_system)
    
      @cmd.stub!(:bosh_cpi).and_return("aws")
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:flavor, 'm1.large')
      @cmd.add_service_node("redis", 2)

      @cmd.system_config.redis.size.should == 1
      redis_config = @cmd.system_config.redis.first
      redis_config["flavor"].should == "m1.large"
      redis_config["count"].should == 2
    end

    it "shows the common internal password" do
      generate_new_system
      @cmd.system_config.common_password.should == 'c1oudc0wc1oudc0w'
      @cmd.show_password
    end

    # create some 'deployments/*.yml' files and
    # assert that bosh attempted to deploy each one:
    #   bosh deployment deployments/aaa.yml
    #   bosh deploy
    it "deploys all the manifests" do
      generate_new_system
      chdir(@cmd.system + "/deployments") do
        cp(spec_asset("deployments/aws-core-only.yml"), "aws-core-only.yml")
        cp(spec_asset("deployments/aws-core-2-m1.xlarge-dea.yml"), "deas.yml")
      end
      @cmd.should_receive(:set_deployment).exactly(2).times
      @cmd.should_receive(:sh).with("bosh -n --color deploy").exactly(2).times
      @cmd.should_receive(:sh).with("sudo gem install vmc --no-ri --no-rdoc")
      @cmd.should_receive(:sh).with("vmc target http://api.mycompany.com")
      @cmd.should_receive(:sh).with(
        "vmc register drnic@starkandwayne.com --password c1oudc0wc1oudc0w --verify c1oudc0wc1oudc0w")
      @cmd.deploy
    end

    it "watches nats traffic within CF deployment" do
      generate_new_system
      @cmd.should_receive(:deployment_manifest_path).with("core").
        and_return(spec_asset("deployments/aws-core-only.yml"))
      @cmd.should_receive(:sh).with("nats-sub '*.*' -s nats://nats:c1oudc0wc1oudc0w@1.2.3.4:4222")
      @cmd.watch_nats
    end

    it "returns bosh_release_versions" do
      @cmd.should_receive(:bosh_releases).exactly(3).times.and_return([
        {"name"=>"appcloud", "versions"=>["124", "126"], "in_use"=>[]},
        {"name"=>"appcloud-dev", "versions"=>["124.1-dev", "126.1-dev"], "in_use"=>[]},
      ])
      @cmd.bosh_release_versions("appcloud").should == ["124", "126"]
      @cmd.bosh_release_versions("appcloud-dev").should == ["124.1-dev", "126.1-dev"]
      @cmd.bosh_release_versions("XXX").should == []
    end
  end
end