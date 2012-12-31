# Copyright (c) 2012-2013 Stark & Wayne, LLC

require 'bosh-cloudfoundry'

module Bosh::Cli::Command
  class CloudFoundry < Base
    include Bosh::Cli::DeploymentHelper
    include Bosh::Cli::VersionCalc
    include Bosh::CloudFoundry::ConfigOptions
    include FileUtils

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

    usage "cf micro"
    desc "create and deploy Micro CloudFoundry"
    option "--ip ip", String, "Static IP for CloudController/router, e.g. 1.2.3.4"
    option "--dns dns", String, "Base DNS for CloudFoundry applications, e.g. vcap.me"
    option "--cf-release name", String, "Name of BOSH release uploaded to target BOSH"
    option "--skip-validations", "Skip all validations"
    def cf_micro_and_deploy(name="demo")
      confirm_or_prompt_all_defaults
      cf_config.cf_release_name = DEFAULT_CF_RELEASE_NAME
      cf_config.save
      
      main_ip, root_dns = confirm_or_choose_micro_system
      confirm_or_upload_release
      confirm_or_upload_stemcell
      generate_micro_system(name, main_ip, root_dns)
      set_system(name)
      deploy
    end

    usage "cf system"
    desc "create/set/show current CloudFoundry system"
    option "--ip ip", String, "Static IP for CloudController/router, e.g. 1.2.3.4"
    option "--dns dns", String, "Base DNS for CloudFoundry applications, e.g. vcap.me"
    option "--cf-release name", String, "Name of BOSH release uploaded to target BOSH"
    option "--skip-validations", "Skip all validations"
    def cf_system(name=nil)
      if name
        new_or_set_system(name)
      else
        show_system
      end
    end

    usage "cf upload stemcell"
    desc "download/create stemcell & upload to BOSH"
    option "--latest", "Use latest stemcell; possibly not tagged stable"
    option "--custom", "Create custom stemcell from BOSH git source"
    def upload_stemcell
      stemcell_type = "stable"
      stemcell_type = "latest" if options[:latest]
      stemcell_type = "custom" if options[:custom]
      create_or_download_stemcell_then_upload(stemcell_type)
    end

    usage "cf upload release"
    desc "fetch & upload public cloudfoundry release to BOSH"
    option "--edge", "Create development release from very latest cf-release commits"
    def upload_release
      create_edge_development_release = options[:edge]
      clone_or_update_cf_release
      if create_edge_development_release
        create_dev_release
        upload_dev_release
      else
        upload_latest_final_release
      end
    end

    usage "cf dea"
    desc  "Run more applications by changing Droplet Execution Agent (DEA) server configuration"
    option "--count count", Integer, "Number of servers for running applications"
    option "--flavor flavor", String, "Flavor of server to use for all DEA servers, e.g. m1.large for AWS"
    def set_dea_servers
      confirm_system

      server_count = options[:count]
      server_flavor = options[:flavor]
      unless non_interactive?
        unless server_flavor
          server_flavor = ask("Flavor of server for DEAs? ") do |q|
            q.default = default_dea_server_flavor
          end
        end
        unless server_count
          server_count = ask("Number of DEA servers? ", Integer) { |q| q.default = 2 }
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
      confirm_system

      validate_service_name(service_name)

      server_count = options[:count]
      server_flavor = options[:flavor]
      unless non_interactive?
        unless server_flavor
          server_flavor = ask("Flavor of server for #{service_name} service nodes? ") do |q|
            q.default = default_service_server_flavor(service_name)
          end
        end
        unless server_count
          server_count = ask("Number of #{service_name} service nodes? ", Integer) { |q| q.default = 1 }
        end
      end
      unless server_flavor && server_flavor
        err("Must provide server count and flavor values")
      end
      validate_compute_flavor(server_flavor)

      generate_service_servers(service_name, server_count, server_flavor)
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
      return true if skip_validations?
      if bosh_target
        say("Current BOSH is '#{bosh_target.green}'")
      else
        err("BOSH target not set")
      end
    end

    def confirm_system
      return true if skip_validations?
      if system
        say("Current CloudFoundry system is '#{system.green}'")
      else
        err("CloudFoundry system not set")
      end
    end

    # @return [String] label for the CPI being used by the target BOSH
    # * "aws" - AWS
    # 
    # Yet to be supported by bosh-cloudfoundry:
    # * "openstack" - VMWare vSphere
    # * "vsphere" - VMWare vSphere
    # * "vcloud" - VMWare vCloud
    def bosh_provider
      if aws?
        "aws"
      else
        err("Please implement cf.rb's bosh_provider for this IaaS")
      end
    end

    # Deploying CloudFoundry to AWS?
    # Is the target BOSH's IaaS using the AWS CPI?
    # FIXME Currently only AWS is supported so its always AWS
    def aws?
      true
    end

    # User is prompted for common values at the
    # start of a command rather than intermittently
    # during a long-running command.
    def confirm_or_prompt_all_defaults
      confirm_bosh_target
      cf_release_dir
      stemcells_dir
    end

    # User is prompted for values required for
    # Micro CloudFoundry deployment
    # @return [Array] of [main_ip, root_dns]
    def confirm_or_choose_micro_system
      main_ip = choose_main_ip # options[:ip]
      root_dns = choose_root_dns # options[:dns]

      validate_dns_a_record("api.#{root_dns}", main_ip)
      validate_dns_a_record("demoapp.#{root_dns}", main_ip)

      [main_ip, root_dns]
    end

    # Confirms that the requested release name is
    # already uploaded to BOSH, else
    # proceeds to upload the release
    def confirm_or_upload_release
      unless cf_release_name
        cf_config.cf_release_name = DEFAULT_CF_RELEASE_NAME
        if options[:edge]
          cf_config.cf_release_name += "-dev"
        end
        cf_config.save
      end
      say "Using BOSH release name #{cf_release_name}".green
      unless bosh_release_names.include?(cf_release_name)
        say "BOSH does not contain release #{cf_release_name.green}, uploading...".yellow
        upload_release
      end
    end
    
    # Confirms that a stemcell has been uploaded
    # and if so, determines its name/version.
    # Otherwise, uploads the latest stable
    # stemcell.
    #
    # At a more granular level:
    #   Are there any stemcells uploaded?
    #     If no, then upload one then set cf_stemcell_version
    #   If there are stemcells
    #     If cf_stemcell_version is set and its not in stemcell list
    #       then change cf_stemcell_version to the latest stemcell
    #     Else if cf_stemcell_version not set, then set to latest stemcell
    def confirm_or_upload_stemcell
      unless latest_bosh_stemcell_version
        say "There are no stemcells available in BOSH yet, so uploading one..."
        upload_stemcell
      end
      unless cf_stemcell_version
        cf_config.cf_stemcell_version = latest_bosh_stemcell_version
        cf_config.save
      end
      unless bosh_stemcell_versions.include?(cf_stemcell_version)
        say "Requested stemcell version #{cf_stemcell_version} is not available.".red
        cf_config.cf_stemcell_version = latest_bosh_stemcell_version
        cf_config.save
      end
      say "Using stemcell version #{cf_stemcell_version}".green
    end
    

    def confirm_cf_release_name
      return true if skip_validations?
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
        # [{"name"=>"appcloud", "versions"=>["126.1-dev"], "in_use"=>[]}]
        releases = director.list_releases
        releases.map { |rel| rel["name"] }
      end
    end

    # List of versions of stemcell called "bosh-stemcell" that are available
    # in target BOSH.
    # Ordered by version number.
    # @return [Array] BOSH stemcell versions available in target BOSH, e.g. ["0.6.4", "0.6.7"]
    def bosh_stemcell_versions
      @bosh_stemcell_versions ||= begin
        # [{"name"=>"bosh-stemcell", "version"=>"0.6.7", "cid"=>"ami-9730bffe"}]
        stemcells = director.list_stemcells
        stemcells.select! {|s| s["name"] == "bosh-stemcell"}
        stemcells.map { |rel| rel["version"] }.sort { |v1, v2|
          version_cmp(v1, v2)
        }
      end
    end

    # Largest version number BOSH stemcell ("bosh-stemcell")
    # @return [String] version number, e.g. "0.6.7"
    def latest_bosh_stemcell_version
      bosh_stemcell_versions.last
    end

    # Creates/downloads a stemcell; then uploads it to target BOSH
    # If +stemcell_type+ is "stable", then download the latest stemcell tagged "stable"
    # If +stemcell_type+ is "latest", then download the latest stemcell, might not be "stable"
    # If +stemcell_type+ is "custom", then create the stemcell from BOSH source
    def create_or_download_stemcell_then_upload(stemcell_type)
      confirm_bosh_target # fails if CLI is not targeting a BOSH
      if stemcell_type.to_s == "custom"
        create_custom_stemcell
        validate_stemcell_created_successfully
        stemcell_path = move_and_return_created_stemcell
      else
        stemcell_name = bosh_stemcell_name(stemcell_type)
        stemcell_path = download_stemcell(stemcell_name)
      end
      upload_stemcell_to_bosh(stemcell_path)
    end

    # Creates a custom stemcell and copies it into +stemcells_dir+
    # @return [String] path to the new stemcell file
    def create_custom_stemcell
      if generated_stemcell
        say "Skipping stemcell creation as one sits in the tmp folder waiting patiently..."
      else
        say "Creating new stemcell for '#{bosh_provider.green}'..."
        chdir(repos_dir) do
          clone_or_update_repository("bosh", bosh_git_repo)
          chdir("bosh/agent") do
            sh "bundle install --without development test"
            sh "sudo bundle exec rake stemcell2:basic['#{bosh_provider}']"
            sh "sudo chown -R vcap:vcap /var/tmp/bosh/agent-*"
          end
        end
      end
    end

    def generated_stemcell
      @generated_stemcell ||= Dir['/var/tmp/bosh/agent-*/work/work/*.tgz'].first
    end

    def validate_stemcell_created_successfully
      err "Stemcell was not created successfully" unless generated_stemcell
    end

    # Locates the newly created stemcell, moves it into +stemcells_dir+
    # and returns the path of its final resting place
    # @return [String] path to new stemcell file; or nil if no stemcell found
    def move_and_return_created_stemcell
      mv generated_stemcell, "#{stemcells_dir}/"
      File.join(stemcells_dir, File.basename(generated_stemcell))
    end

    def clone_or_update_repository(name, repo_uri)
      if File.directory?(name)
        chdir(name) do
          say "Updating #{name} repositry..."
          sh "git pull origin master"
        end
      else
        say "Cloning #{repo_uri} repositry..."
        sh "git clone #{repo_uri} #{name}"
      end
    end

    # The latest relevant public stemcell name
    # Runs 'bosh public stemcells' and parses the output. Currently expects the output
    # to look like:
    # +-----------------------------------------+------------------------+
    # | Name                                    | Tags                   |
    # +-----------------------------------------+------------------------+
    # | bosh-stemcell-0.5.2.tgz                 | vsphere                |
    # | bosh-stemcell-aws-0.6.4.tgz             | aws, stable            |
    # | bosh-stemcell-aws-0.6.7.tgz             | aws                    |
    def bosh_stemcell_name(stemcell_type)
      tags = [bosh_provider]
      tags << "stable" if stemcell_type == "stable"
      bosh_stemcells_cmd = "bosh public stemcells --tags #{tags.join(',')}"
      say "Locating bosh stemcell, running '#{bosh_stemcells_cmd}'..."
      `#{bosh_stemcells_cmd} | grep ' bosh-stemcell-' | awk '{ print $2 }' | sort -r | head -n 1`.strip
    end

    def download_stemcell(stemcell_name)
      mkdir_p(stemcells_dir)
      chdir(stemcells_dir) do
        if File.exists?(stemcell_name)
          say "Stemcell #{stemcell_name} already downloaded".yellow
        else
          say "Downloading public stemcell #{stemcell_name}..."
          bosh_cmd("download public stemcell #{stemcell_name}")
        end
      end
      File.join(stemcells_dir, stemcell_name)
    end

    def upload_stemcell_to_bosh(stemcell_path)
      say "Uploading stemcell located at #{stemcell_path}..."
      bosh_cmd("upload stemcell #{stemcell_path}")
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
            sh "git update-index --assume-unchanged config/final.yml 2>/dev/null"
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

    def upload_latest_final_release
      release_number = latest_final_release_tag_number
      chdir(cf_release_dir) do
        bosh_cmd "upload release releases/appcloud-#{release_number}.yml"
      end
    end

    # Examines the git tags of the cf-release repo and
    # finds the latest tag for a release (v126 or v119-fixed)
    # and returns the integer value (126 or 119).
    # @return [Integer] the number of the latest final release tag
    def latest_final_release_tag_number
      # FIXME this assumes the most recent tag is a final release:
      #  (v126)
      #  (v126, origin/built)
      #  (v119-fixed)
      # But it might return an empty row
      # Example values in the output from the "git log" command below is:
      # (v126, origin/built)
      # (v125)
      # (origin/te)
      # (v121)
      # (v120)
      # (v119-fixed)
      # (v119)
      # (origin/v113-fix)
      # (v109)
      # 
      # (origin/warden)
      # 
      chdir(cf_release_dir) do
        latest_git_tag = `git log --tags --simplify-by-decoration --pretty='%d' | head -n 1`
        if latest_git_tag =~ /v(\d+)/
          return $1.to_i
        else
          say "The following command did not return a v123 formatted number:".red
          say "git log --tags --simplify-by-decoration --pretty='%d' | head -n 1"
          say "Method #latest_final_release_tag_number needs to be fixed"
          err("Please raise an issue with https://github.com/StarkAndWayne/bosh-cloudfoundry/issues")
        end
      end
    end

    def create_dev_release(release_name="appcloud-dev")
      chdir(cf_release_dir) do
        write_dev_config_file(release_name)
        sh "bosh create release --with-tarball --force"
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
      return true if skip_validations?
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

    def generate_micro_system(system_name, main_ip, root_dns)
      director_uuid = "DIRECTOR_UUID"
      release_name = cf_release_name
      stemcell_version = cf_stemcell_version
      if aws?
        resource_pool_cloud_properties = "instance_type: m1.xlarge"
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
        require 'bosh-cloudfoundry/generators/micro_system_generator'
        Bosh::CloudFoundry::Generators::MicroSystemGenerator.start([
          system_name, main_ip, root_dns,
          director_uuid, release_name, stemcell_version,
          resource_pool_cloud_properties, persistent_disk,
          dea_max_memory,
          admin_email,
          router_password, nats_password, ccdb_password])
      end
    end

    def generate_system(system_name, main_ip, root_dns)
      director_uuid = "DIRECTOR_UUID"
      release_name = "appcloud"
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
      return true if skip_validations?
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
      release_name = "appcloud"
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
      return true if skip_validations?
      unless supported_services.include?(service_name)
        supported_services_list = supported_services.join(", ")
        err("Service '#{service_name}' is not a supported service, such as #{supported_services_list}")
      end
    end

    def supported_services
      %w[postgresql redis]
    end

    def generate_service_servers(service_name, server_count, server_flavor)
      director_uuid = "DIRECTOR_UUID"
      release_name = "appcloud"
      stemcell_version = "0.6.4"
      if aws?
        resource_pool_cloud_properties = "instance_type: #{server_flavor}"
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
          service_name, server_count, server_flavor,
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

    def default_service_server_flavor(service_name)
      if aws?
        "m1.xlarge"
      else
        err("Please implement cf.rb's default_service_server_flavor for this IaaS")
      end
    end

    # @return [Array] of [Hash] for each supported compute flavor
    # Example [Hash] { :bits => 0, :cores => 2, :disk => 0, 
    #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
    def aws_compute_flavors
      Fog::Compute::AWS::FLAVORS
    end

    def bosh_cmd(command)
      full_command = "bosh -n --color #{command}"
      sh full_command
    end
  end
end
