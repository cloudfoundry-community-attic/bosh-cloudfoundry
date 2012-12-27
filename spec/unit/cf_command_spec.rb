# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::Cli::Command::Base do

  before :each do
    @config = File.join(Dir.mktmpdir, "bosh_config")
    @cf_config = File.join(Dir.mktmpdir, "bosh_cf_config")
    @cache = File.join(Dir.mktmpdir, "bosh_cache")
    @systems_dir = File.join(Dir.mktmpdir, "systems")
    @releases_dir = File.join(Dir.mktmpdir, "releases")
    @stemcells_dir = File.join(Dir.mktmpdir, "stemcells")
    FileUtils.mkdir_p(@systems_dir)
    FileUtils.mkdir_p(@releases_dir)
    FileUtils.mkdir_p(@stemcells_dir)
  end

  describe Bosh::Cli::Command::CloudFoundry do

    before :each do
      @cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
      @cmd.add_option(:non_interactive, true)
      @cmd.add_option(:config, @config)
      @cmd.add_option(:cf_config, @cf_config)
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
      @cmd.should_receive(:`).
        with("bosh public stemcells --tags aws,stable | grep ' bosh-stemcell-' | awk '{ print $2 }' | sort -r | head -n 1").
        and_return("bosh-stemcell-aws-0.6.7.tgz")
      @cmd.should_receive(:sh).
        with("COLUMNS=80 bosh -n download public stemcell bosh-stemcell-aws-0.6.7.tgz")
      @cmd.should_receive(:sh).
        with("COLUMNS=80 bosh -n upload stemcell #{@stemcells_dir}/bosh-stemcell-aws-0.6.7.tgz")

      @cmd.add_option(:stemcells_dir, @stemcells_dir)
      @cmd.upload_stemcell
    end

    it "creates bosh stemcell and uploads it"

    it "updates/creates/uploads cf-release" do
      cf_releases_dir = File.join(@releases_dir, "cf-release")
      FileUtils.mkdir_p(cf_releases_dir)
      @cmd.add_option(:cf_release_dir, @releases_dir)

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
      @cmd.should_receive(:sh).with("git submodule update --init")
      @cmd.should_receive(:write_dev_config_file).with("cf-dev")
      @cmd.should_receive(:sh).with("bosh create release --force")
      @cmd.should_receive(:sh).with("bosh -n --color upload release")
      @cmd.upload_release
    end

    def generate_new_system(cmd = nil)
      cmd ||= begin
        cmd = Bosh::Cli::Command::CloudFoundry.new(nil)
        cmd.add_option(:non_interactive, true)
        cmd.add_option(:config, @config)
        cmd.add_option(:cf_config, @cf_config)
        cmd.add_option(:cache_dir, @cache)
        cmd.add_option(:base_systems_dir, @systems_dir)
        cmd
      end

      cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      cmd.should_receive(:bosh_release_names).and_return(['cf-dev', 'cf-production'])
      cmd.should_receive(:validate_dns_a_record).with("api.mycompany.com", '1.2.3.4').and_return(true)
      cmd.should_receive(:validate_dns_a_record).with("demoapp.mycompany.com", '1.2.3.4').and_return(true)

      cmd.add_option(:ip, '1.2.3.4')
      cmd.add_option(:dns, 'mycompany.com')
      cmd.add_option(:cf_release, 'cf-dev')

      cmd.system.should be_nil
      cmd.cf_system("production")
    end

    it "generates new system folder/manifests, using all options" do
      generate_new_system(@cmd)
      File.basename(@cmd.system).should == "production"

      FileUtils.chdir(@cmd.system) do
        File.should be_exist("deployments/production-main.yml")
        files_match("deployments/production-main.yml", spec_asset("deployments/production-main.yml"))
      end
    end

    it "adds dea servers" do
      generate_new_system
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:count, '3')
      @cmd.add_option(:flavor, 'm1.large')
      @cmd.set_dea_servers

      FileUtils.chdir(@cmd.system) do
        File.should be_exist("deployments/production-dea.yml")
        files_match("deployments/production-dea.yml", spec_asset("deployments/production-dea-aws-3-m1large.yml"))
      end
    end

    it "fails for unknown service" do
      generate_new_system
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      expect {
        @cmd.set_service_servers("UNKNOWN")
      }.to raise_error(Bosh::Cli::CliError)
    end

    it "adds postgresql nodes" do
      generate_new_system
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:count, '4')
      @cmd.add_option(:flavor, 'm1.large')
      @cmd.set_service_servers("postgresql")

      FileUtils.chdir(@cmd.system) do
        File.should be_exist("deployments/production-postgresql.yml")
        files_match("deployments/production-postgresql.yml", spec_asset("deployments/production-postgresql-aws-4-m1large.yml"))
      end
    end

    it "adds redis nodes" do
      generate_new_system
      @cmd.stub!(:bosh_target).and_return("http://9.8.7.6:25555")
      @cmd.add_option(:count, '2')
      @cmd.add_option(:flavor, 'm1.large')
      @cmd.set_service_servers("redis")

      FileUtils.chdir(@cmd.system) do
        File.should be_exist("deployments/production-redis.yml")
        files_match("deployments/production-redis.yml", spec_asset("deployments/production-redis-aws-2-m1large.yml"))
      end
    end

    it "deploys all the manifests"
  end
end