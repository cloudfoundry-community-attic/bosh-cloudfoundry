# Copyright (c) 2012-2013 Stark & Wayne, LLC

require 'bosh-cloudfoundry'

module Bosh::Cli::Command
  class CloudFoundry < Base
    include Bosh::Cli::DeploymentHelper
    include FileUtils

    DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_cf_config")
    DEFAULT_BASE_SYSTEM_PATH = "/var/vcap/store/systems"
    DEFAULT_RELEASES_PATH = "/var/vcap/store/releases"

    # @return [Bosh::CloudFoundry::Config] Current CF configuration
    def cf_config
      @cf_config ||= begin
        config_file = options[:cf_config] || DEFAULT_CONFIG_PATH
        cf_config = Bosh::CloudFoundry::Config.new(config_file)
        cf_config.cf_release_git_repo ||= "git://github.com/cloudfoundry/cf-release.git"
        cf_config.save
        cf_config
      end
    end

    # @return [String] BOSH target to manage CloudFoundry
    def bosh_target
      options[:bosh_target] || config.target
    end

    # @return [String] CloudFoundry system path
    def system
      options[:system] || cf_config.cf_system
    end

    # @return [String] CloudFoundry system name
    def system_name
      @system_name ||= File.basename(File.expand_path(system))
    end

    # @return [String] CloudFoundry BOSH release git URI
    def cf_release_git_repo
      options[:cf_release_git_repo] || cf_config.cf_release_git_repo
    end

    # @return [String] Path to store BOSH release projects
    def releases_dir
      options[:releases_dir] || cf_config.releases_dir || choose_releases_dir
    end

    # @return [String] Path to cf-release BOSH release
    def cf_release_dir
      options[:cf_release_dir] || cf_config.cf_release_dir || begin
        cf_config.cf_release_dir = File.join(releases_dir, "cf-release")
        cf_config.save
        cf_config.cf_release_dir
      end
    end

    # @return [String] Path to store BOSH systems (collections of deployments)
    def base_systems_dir
      @base_systems_dir ||= options[:base_systems_dir] || cf_config.base_systems_dir || begin
        if non_interactive?
          err "Please set base_systems_dir configuration for non-interactive mode"
        end
        
        base_systems_dir = ask("Path for to store all CloudFoundry systems: ") {
          |q| q.default = DEFAULT_BASE_SYSTEM_PATH }
        cf_config.base_systems_dir = File.expand_path(base_systems_dir)
        unless File.directory?(cf_config.base_systems_dir)
          say "Creating systems path #{cf_config.base_systems_dir}"
          FileUtils.mkdir_p(cf_config.base_systems_dir)
        end
        cf_config.save
        cf_config.base_systems_dir
      end
    end

    usage "cf"
    desc  "show cf bosh sub-commands"
    def cf_help
      say("bosh cf sub-commands:")
      nl
      cmds = Bosh::Cli::Config.commands.values.find_all {|c|
        c.usage =~ /^cf/
      }
      Bosh::Cli::Command::Help.list_commands(cmds)
    end

    usage "cf deploy"
    desc  "deploy cloudfoundry"
    def deploy
    end

    usage "cf system"
    desc "create/set/show current CloudFoundry system"
    option "--ip ip", String, "Static IP for CloudController/router, e.g. 1.2.3.4"
    option "--dns dns", String, "Base DNS for CloudFoundry applications, e.g. vcap.me"
    option "--cf-release name", String, "Name of BOSH release uploaded to target BOSH"
    def cf_system(name=nil)
      if name
        new_or_set_system(name)
      else
        show_system
      end
    end

    usage "cf upload release"
    desc "fetch & upload public cloudfoundry release to BOSH"
    def upload_release(release_name="cf-dev")
      cf_config.cf_release_name = release_name
      cf_config.save
      clone_or_update_cf_release
      create_dev_release(release_name)
      upload_dev_release
    end

    usage "cf dea"
    desc  "Run more applications by changing Droplet Execution Agent (DEA) server configuration"
    option "--count count", Integer, "Number of servers for running applications"
    option "--flavor flavor", String, "Flavor of server to use for all DEA servers, e.g. m1.large for AWS"
    def set_dea_servers
      confirm_bosh_target # fails if CLI is not targeting a BOSH
      confirm_system

      server_count = options[:count]
      server_flavor = options[:flavor]
      unless non_interactive?
        unless server_flavor
          server_flavor = ask("Flavor of server for DEAs?") do |q|
            q.default = default_dea_server_flavor
          end
        end
        unless server_count
          server_count = ask("Number of DEA servers?", Integer) { |q| q.default = 2 }
        end
      end
      unless server_flavor && server_flavor
        err("Must provide server count and flavor values")
      end
      validate_compute_flavor(server_flavor)

      generate_dea_servers(server_count, server_flavor)
    end

    usage "cf service"
    desc  "Support new/more services"
    option "--count count", Integer, "Number of servers for service"
    option "--flavor flavor", String, "Flavor of server to use for service"
    def set_service_servers(service_name)
      confirm_bosh_target # fails if CLI is not targeting a BOSH
      confirm_system

      validate_service_name(service_name)

      service_server_count = options[:count]
      service_server_flavor = options[:flavor]
      validate_compute_flavor(service_server_flavor)

      generate_service_servers(service_name, service_server_count, service_server_flavor)
    end

    # Create system if +name+ doesn't exist
    # Set +system+ to specified name
    def new_or_set_system(name)
      system_dir = File.join(base_systems_dir, name)
      if File.directory?(system_dir)
        set_system(name)
      else
        new_system(name)
      end
    end

    def set_system(name)
      system_dir = File.join(base_systems_dir, name)
      unless File.directory?(system_dir)
        err "CloudFoundry system path '#{system_dir.red}` does not exist"
      end
      
      say "CloudFoundry system set to '#{system_dir.green}'"
      cf_config.cf_system = system_dir
      cf_config.save
    end

    def new_system(name)
      confirm_bosh_target # fails if CLI is not targeting a BOSH
      cf_release_name = confirm_cf_release_name # returns false if not set or no-longer available
      cf_release_name ||= choose_cf_release_name # options[:cf_release] # choose or upload

      main_ip = choose_main_ip # options[:ip]
      root_dns = choose_root_dns # options[:dns]

      validate_dns_a_record("api.#{root_dns}", main_ip)
      validate_dns_a_record("demoapp.#{root_dns}", main_ip)

      generate_system(name, main_ip, root_dns)
      set_system(name)
    end

    def show_system
      say(system ? "Current CloudFoundry system is '#{system.green}'" : "CloudFoundry system not set")
    end

    def confirm_bosh_target
      if bosh_target
        say("Current BOSH is '#{bosh_target.green}'")
      else
        err("BOSH target not set")
      end
    end

    def confirm_system
      if system
        say("Current CloudFoundry system is '#{system.green}'")
      else
        err("CloudFoundry system not set")
      end
    end

    # Deploying CloudFoundry to AWS?
    # Is the target BOSH's IaaS using the AWS CPI?
    # FIXME Currently only AWS is supported so its always AWS
    def aws?
      @fog = Fog::Compute['AWS'] # this is currently just to load fog/aws code
      true
    end

    def confirm_cf_release_name
      if release_name = options[:cf_release] || cf_config.cf_release_name
        unless bosh_release_names.include?(release_name)
          err("BOSH target #{bosh_target} does not have a release '#{release_name.red}'")
        end
        release_name
      else
        false
      end
    end

    # @return [Array] BOSH releases available in target BOSH
    def bosh_release_names
      @bosh_releases ||= begin
        # [{"name"=>"cf-dev", "versions"=>["126.1-dev"], "in_use"=>[]}]
        releases = director.list_releases
        releases.map { |rel| rel["name"] }
      end
    end

    # @return [String] Primary static IP for CloudController & Router
    def choose_main_ip
      @main_ip = options[:ip] || begin
        err("Currently, please provide static IP via --ip flag")
      end
    end

    # @return [String] Root DNS for applications & CloudController API
    def choose_root_dns
      @root_dns = options[:dns] || begin
        err("Currently, please provide root DNS via --dns flag")
      end
    end

    # assume unchanged config/final.yml
    def clone_or_update_cf_release
      cf_release_dirname = File.basename(cf_release_dir)
      if File.directory?(cf_release_dir)
        chdir(cf_release_dir) do
          sh "git pull origin master"
        end
      else
        chdir(releases_dir) do
          sh "git clone #{cf_release_git_repo} #{cf_release_dirname}"
          chdir(cf_release_dirname) do
            sh "git update-index --assume-unchanged config/final.yml"
          end
        end
      end
      chdir(cf_release_dir) do
        say "Rewriting all git:// & git@ to https:// ..."
        # Snippet written by Mike Reeves <swampfoxmr@gmail.com> on bosh-users mailing list
        # Date 2012-12-06
        sh "sed -i 's#git@github.com:#https://github.com/#g' .gitmodules"
        sh "sed -i 's#git://github.com#https://github.com#g' .gitmodules"
        sh "git submodule update --init"
      end
    end

    def choose_releases_dir
      if non_interactive?
        err "Please set releases_dir configuration for non-interactive mode"
      end
      
      releases_dir = ask("Path to store all BOSH releases: ") {
        |q| q.default = DEFAULT_RELEASES_PATH }

      cf_config.releases_dir = File.expand_path(releases_dir)
      unless File.directory?(cf_config.releases_dir)
        say "Creating releases path #{cf_config.releases_dir}"
        FileUtils.mkdir_p(cf_config.releases_dir)
      end
      cf_config.save
      cf_config.releases_dir
    end

    def create_dev_release(release_name)
      chdir(cf_release_dir) do
        write_dev_config_file(release_name)
        sh "bosh create release --force"
      end
    end

    def write_dev_config_file(release_name)
      dev_config_file = "config/dev.yml"
      if File.exist?(dev_config_file)
        dev_config = YAML.load_file(dev_config_file)
      else
        dev_config = {}
      end
      dev_config["dev_name"] = release_name
      File.open(dev_config_file, "w") { |file| file << dev_config.to_yaml }
    end

    def upload_dev_release
      chdir(cf_release_dir) do
        sh "bosh -n --color upload release"
      end
    end

    # Validates that +domain+ is an A record that resolves to +expected_ip_addresses+
    # and no other IP addresses.
    # * +expected_ip_addresses+ is a String (IPv4 address)
    def validate_dns_a_record(domain, expected_ip_address)
      say "Checking that DNS #{domain.green} resolves to IP address #{expected_ip_address.green}... ", " "
      packet = Net::DNS::Resolver.start(domain, Net::DNS::A)
      resolved_a_records = packet.answer.map(&:value)
      if packet.answer.size == 0
        error = "Domain '#{domain.green}' does not resolve to an IP address"
      end
      unless resolved_a_records == [expected_ip_address]
        error = "Domain #{domain} should resolve to IP address #{expected_ip_address}"
      end
      if error
        say "ooh no!".red
        say "Please setup your DNS:"
        say "Subdomain:  * " + "(wildcard)".yellow
        say "IP address: #{expected_ip_address}"
        err(error)
      else
        say "ok".green
        true
      end
    end

    def generate_system(system_name, main_ip, root_dns)
      director_uuid = "DIRECTOR_UUID"
      release_name = "cf-dev"
      stemcell_version = "0.6.4"
      if aws?
        resource_pool_cloud_properties = "instance_type: m1.small"
      else
        err("Please implemenet cf.rb's generate_system for this IaaS")
      end
      persistent_disk = 16192
      dea_max_memory = 2048
      admin_email = "drnic@starkandwayne.com"
      router_password = "router1234"
      nats_password = "mynats1234"
      ccdb_password = "ccdbroot"
      system_dir = File.join(base_systems_dir, system_name)
      mkdir_p(system_dir)
      chdir system_dir do
        require 'bosh-cloudfoundry/generators/new_system_generator'
        Bosh::CloudFoundry::Generators::NewSystemGenerator.start([
          system_name, main_ip, root_dns,
          director_uuid, release_name, stemcell_version,
          resource_pool_cloud_properties, persistent_disk,
          dea_max_memory,
          admin_email,
          router_password, nats_password, ccdb_password])
      end
    end

    # Validates +server_size+ against the known list of instance types/server sizes
    # for the target IaaS.
    #
    # For example, "m1.small" is a valid server size/instance type on all AWS regions
    def validate_compute_flavor(flavor)
      if aws?
        unless aws_compute_flavors.select { |flavor| flavor[:id] == flavor }
          err("Server flavor '#{flavor}' is not a valid AWS compute flavor")
        end
      else
        err("Please implemenet cf.rb's validate_compute_flavor for this IaaS")
      end
    end

    def generate_dea_servers(server_count, server_flavor)
      director_uuid = "DIRECTOR_UUID"
      release_name = "cf-dev"
      stemcell_version = "0.6.4"
      if aws?
        resource_pool_cloud_properties = "instance_type: #{server_flavor}"
      else
        err("Please implemenet cf.rb's generate_dea_servers for this IaaS")
      end
      dea_max_memory = 2048 # FIXME a value based on server flavor RAM?
      nats_password = "mynats1234"
      system_dir = File.join(base_systems_dir, system_name)
      mkdir_p(system_dir)
      chdir system_dir do
        require 'bosh-cloudfoundry/generators/dea_generator'
        Bosh::CloudFoundry::Generators::DeaGenerator.start([
          system_name,
          server_count, server_flavor,
          director_uuid, release_name, stemcell_version,
          resource_pool_cloud_properties,
          dea_max_memory,
          nats_password])
      end
    end

    # Valdiate that +service_name+ is a known, supported service name
    def validate_service_name(service_name)
      unless supported_services.include?(service_name)
        supported_services_list = supported_services.join(", ")
        err("Service '#{service_name}' is not a supported service, such as #{supported_services_list}")
      end
    end

    def supported_services
      %w[postgresql redis]
    end

    def generate_service_servers(service_name, service_server_count, service_server_flavor)
      director_uuid = "DIRECTOR_UUID"
      release_name = "cf-dev"
      stemcell_version = "0.6.4"
      if aws?
        resource_pool_cloud_properties = "instance_type: #{service_server_flavor}"
      else
        err("Please implemenet cf.rb's generate_service_servers for this IaaS")
      end
      persistent_disk = 16192
      nats_password = "mynats1234"
      system_dir = File.join(base_systems_dir, system_name)
      mkdir_p(system_dir)
      chdir system_dir do
        require 'bosh-cloudfoundry/generators/service_generator'
        Bosh::CloudFoundry::Generators::ServiceGenerator.start([
          system_name,
          service_name, service_server_count, service_server_flavor,
          director_uuid, release_name, stemcell_version,
          resource_pool_cloud_properties, persistent_disk,
          nats_password])
      end
    end

    def default_dea_server_flavor
      if aws?
        "m1.large"
      else
        err("Please implement cf.rb's default_server_flavor for this IaaS")
      end
    end

    # @return [Array] of [Hash] for each supported compute flavor
    # Example [Hash] { :bits => 0, :cores => 2, :disk => 0, 
    #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
    def aws_compute_flavors
      Fog::Compute::AWS::FLAVORS
    end
  end
end
