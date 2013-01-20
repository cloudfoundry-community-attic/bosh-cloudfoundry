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

    usage "cf prepare system"
    desc "create CloudFoundry system"
    option "--core-ip ip", String, "Static IP for CloudController/router, e.g. 1.2.3.4"
    option "--root-dns dns", String, "Base DNS for CloudFoundry applications, e.g. vcap.me"
    option "--core-server-flavor flavor", String,
      "Flavor of the CloudFoundry Core server. Default: 'm1.large'"
    option "--release-name name", String,
      "Name of BOSH release within target BOSH. Default: 'appcloud'"
    option "--release-version version", String,
      "Version of target BOSH release within target BOSH. Default: 'latest'"
    option "--stemcell-name name", String,
      "Name of BOSH stemcell within target BOSH. Default: 'bosh-stemcell'"
    option "--stemcell-version version", String,
      "Version of BOSH stemcell within target BOSH. Default: determines latest for stemcell"
    option "--admin-emails email1,email2", Array, "Admin email accounts in created CloudFoundry"
    option "--skip-validations", "Skip all validations"
    def prepare_system(name=nil)
      setup_system_dir(name)
      confirm_or_prompt_all_defaults
      confirm_or_prompt_for_system_requirements
      render_system
      target_core_deployment_manifest
    end

    usage "cf change deas"
    desc "change the number/flavor of DEA servers (servers that run CF apps)"
    option "--flavor flavor", String, "Change flavor of all DEA servers"
    def change_deas(server_count="1")
      confirm_system

      server_count = server_count.to_i # TODO nicer integer validation
      if server_count <= 0
        say "Additional server count (#{server_count}) was less that 1, defaulting to 1"
        server_count = 1
      end

      server_flavor = options[:flavor]
      unless non_interactive?
        unless server_flavor
          server_flavor = ask("Flavor of server for DEAs? ") do |q|
            q.default = default_dea_server_flavor
          end.to_s
        end
      end
      unless server_flavor && server_flavor
        err("Must provide server count and flavor values")
      end
      validate_compute_flavor(server_flavor)

      dea_config = Bosh::CloudFoundry::Config::DeaConfig.build_from_system_config(system_config)
      dea_config.update_count_and_flavor(server_count, server_flavor)

      render_system
    end

    usage "cf add service"
    desc "add additional CloudFoundry service node"
    option "--flavor flavor", String, "Server flavor for additional service nodes"
    def add_service_node(service_name, additional_count=1)
      confirm_system

      validate_service_name(service_name)

      server_flavor = options[:flavor]
      unless non_interactive?
        unless server_flavor
          server_flavor = ask("Flavor of server for #{service_name} service nodes? ") do |q|
            q.default = default_service_server_flavor(service_name)
          end
        end
      end
      unless server_flavor && server_flavor
        err("Must provide server count and flavor values")
      end
      validate_compute_flavor(server_flavor)
      
      service_config = service_config(service_name)
      flavor_cluster = service_config.find_cluster_for_flavor(server_flavor) || {}

      current_count = flavor_cluster["count"] || 0
      server_count = current_count + additional_count.to_i # TODO nicer integer validation
      say "Changing #{service_name} #{server_flavor} from #{current_count} to #{server_count}"
      service_config.update_cluster_count_for_flavor(server_count, server_flavor)

      render_system
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
        upload_final_release
      end
    end

    usage "cf deploy"
    desc  "deploy CloudFoundry system or apply any changes"
    def deploy
      confirm_system
      Dir["#{system}/deployments/*.yml"].each do |deployment|
        set_deployment(deployment)
        bosh_cmd "deploy"
      end
    end

    usage "cf watch nats"
    desc "subscribe to all nats messages within CloudFoundry"
    def watch_nats
      confirm_system
      nats_props = deployment_manifest("core")["properties"]["nats"]
      user, pass = nats_props["user"], nats_props["password"]
      host, port = nats_props["address"], nats_props["port"]
      nats_uri = "nats://#{user}:#{pass}@#{host}:#{port}"
      sh "nats-sub '*.*' -s #{nats_uri}"
    end

    usage "cf show password"
    desc "displays the common password for internal access"
    def show_password
      confirm_system
      say system_config.common_password
    end

    # Creates initial system folder & targets that system folder
    # The +system_config+ configuration does not work until
    # a system folder is created and targeted so that a
    # local configuration manifest can be stored (SystemConfig)
    def setup_system_dir(name)
      system_dir = File.join(base_systems_dir, name)
      unless File.directory?(system_dir)
        say "Creating new system #{name} directory"
        mkdir_p(system_dir)
      end
      set_system(name)
    end

    # Set +system+ to specified name
    def set_system(name)
      system_dir = File.join(base_systems_dir, name)
      unless File.directory?(system_dir)
        err "CloudFoundry system path '#{system_dir.red}` does not exist"
      end
      
      say "CloudFoundry system set to #{system_dir.green}"
      common_config.target_system = system_dir
      common_config.save
    end

    def target_core_deployment_manifest
      if deployment = Dir["#{system}/deployments/*-core.yml"].first
        set_deployment(deployment)
      end
    end
    
    # Helper to tell the CLI to target a specific deployment manifest for the "bosh deploy" command
    def set_deployment(path)
      cmd = Bosh::Cli::Command::Deployment.new
      cmd.set_current(path)
    end

    def confirm_bosh_target
      return true if skip_validations?
      if bosh_target && bosh_target_uuid
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
      base_systems_dir
    end

    # Assert that system configuration is available or prompt for values
    def confirm_or_prompt_for_system_requirements
      generate_generatable_options
      validate_root_dns_maps_to_core_ip
      ensure_security_group_prepared
      validate_compute_flavor(core_server_flavor)
      admin_emails
      confirm_or_upload_release
      confirm_or_upload_stemcell
    end

    # Confirms that the requested release name is
    # already uploaded to BOSH, else
    # proceeds to upload the release
    def confirm_or_upload_release
      unless release_name
        system_config.release_name = DEFAULT_RELEASE_NAME
        if options[:edge]
          system_config.release_name += "-dev"
        end
        system_config.save
      end
      say "Using BOSH release name #{release_name} #{effective_release_version}".green
      unless bosh_release_names.include?(release_name) &&
              bosh_release_versions(release_name).include?(effective_release_version)
        say "BOSH does not contain release #{release_name.green} #{effective_release_version.green}, uploading...".yellow
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
    #     If no, then upload one then set stemcell_version
    #   If there are stemcells
    #     If stemcell_version is set and its not in stemcell list
    #       then change stemcell_version to the latest stemcell
    #     Else if stemcell_version not set, then set to latest stemcell
    def confirm_or_upload_stemcell
      if stemcell_version
        unless bosh_stemcell_versions.include?(stemcell_version)
          say "Stemcell #{stemcell_name} #{stemcell_version} no longer exists on BOSH, choosing another..."
          system_config.stemcell_version = nil
        else
          say "Using stemcell #{stemcell_name} #{stemcell_version}".green
          return
        end
      end
      unless latest_bosh_stemcell_version
        if stemcell_name == DEFAULT_STEMCELL_NAME
          say "Attempting to upload stemcell #{stemcell_name}..."
          upload_stemcell
        else
          say "Please first upload stemcell #{stemcell_name} or change to default stemcell #{DEFAULT_STEMCELL_NAME}"
          exit 1
        end
      end
      unless stemcell_version && stemcell_version.size
        system_config.stemcell_version = latest_bosh_stemcell_version
        system_config.save
      end
      unless bosh_stemcell_versions.include?(stemcell_version)
        say "Requested stemcell version #{stemcell_version} is not available.".yellow
        system_config.stemcell_version = latest_bosh_stemcell_version
        system_config.save
      end
      say "Using stemcell #{stemcell_name} #{stemcell_version}".green
    end
    

    def confirm_release_name
      return true if skip_validations?
      if release_name = options[:cf_release] || system_config.release_name
        unless bosh_release_names.include?(release_name)
          err("BOSH target #{bosh_target} does not have a release '#{release_name.red}'")
        end
        release_name
      else
        false
      end
    end

    # @return [Array] BOSH releases available in target BOSH
    # [{"name"=>"appcloud", "versions"=>["124", "126"], "in_use"=>[]}]
    def bosh_releases
      @bosh_releases ||= releases = director.list_releases
    end

    # @return [Array] BOSH release names available in target BOSH
    def bosh_release_names
      @bosh_release_names ||= bosh_releases.map { |rel| rel["name"] }
    end

    # @return [Array] BOSH release versions for specific release name in target BOSH
    def bosh_release_versions(release_name)
      if release = bosh_releases.find { |rel| rel["name"] == release_name }
        release["versions"]
      else
        []
      end
    end

    # @return [Version String] BOSH version number; converts 'latest' into actual version
    def effective_release_version
      if release_version == "latest"
        latest_final_release_tag_number.to_s
      else
        release_version.to_s
      end
    end

    # Largest version number BOSH stemcell ("bosh-stemcell")
    # @return [String] version number, e.g. "0.6.7"
    def latest_bosh_stemcell_version
      @latest_bosh_stemcell_version ||= begin
        if bosh_stemcell_versions.size > 0
          say "Available BOSH stemcells '#{stemcell_name}': #{bosh_stemcell_versions.join(', ')}"
          bosh_stemcell_versions.last
        else
          say "No stemcells '#{stemcell_name}' uploaded yet"
          nil
        end
      end
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
      @bosh_stemcell_versions = nil # reset cache
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

    def upload_final_release
      release_number = use_latest_release? ? 
        latest_final_release_tag_number :
        release_version
      chdir(cf_release_dir) do
        bosh_cmd "upload release releases/appcloud-#{release_number}.yml"
      end
      @bosh_releases = nil # reset cache
    end

    # FIXME why not look in releases/final.yml to get the number?
    # then it would also work for dev_releases?

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
      @bosh_releases = nil # reset cache
    end

    # It is assumed that there is only one m
    def validate_root_dns_maps_to_core_ip
      core_ip  # prompts if not already known
      root_dns # prompts if not already known

      validate_dns_a_record("api.#{root_dns}", core_ip)
      validate_dns_a_record("demoapp.#{root_dns}", core_ip)
    end

    # Ensures that the security group exists
    # and has the correct ports open
    def ensure_security_group_prepared
      provider.create_security_group(system_config.security_group, required_public_ports)
    end

    # TODO this could change based on jobs being included
    def required_public_ports
      {
        ssh: 22,
        http: 80,
        https: 433,
        postgres: 2544,
        resque: 3456,
        nats: 4222,
        router: 8080,
        # TODO serialization_data_server: 8090, - if NFS enabled
        uaa: 8100
      }
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

    # If any system_config values that are needed are not provided,
    # then ensure that a generated value is stored
    def generate_generatable_options
      common_password
      if aws?
        security_group
      end
    end

    # Renders the +SystemConfig+ model (+system_config+) into the system's
    # deployment manifest(s).
    def render_system
      renderer = Bosh::CloudFoundry::SystemDeploymentManifestRenderer.new(
        system_config, common_config, config)
      renderer.perform
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

    def service_config(service_name)
      case service_name.to_sym
      when :postgresql
        Bosh::CloudFoundry::Config::PostgresqlServiceConfig.build_from_system_config(system_config)
      when :redis
        Bosh::CloudFoundry::Config::RedisServiceConfig.build_from_system_config(system_config)
      else
        raise "please add #{service_name} support to #service_config method"
      end
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

    def default_core_server_flavor
      if aws?
        "m1.large"
      else
        err("Please implement cf.rb's default_core_server_flavor for this IaaS")
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

    # a helper object for the target BOSH provider
    def provider
      @provider ||= Bosh::CloudFoundry::Providers.for_bosh_provider_name(system_config)
    end

    def bosh_cmd(command)
      full_command = "bosh -n --color #{command}"
      sh full_command
    end

  end
end
