require "yaml"

require "bosh/cloudfoundry"

module Bosh::Cli::Command
  class CloudFoundry < Base
    include FileUtils
    include Bosh::Cli::Validation

    usage "cf"
    desc  "show micro cf sub-commands"
    def cf_help
      say("bosh cf sub-commands:")
      nl
      cmds = Bosh::Cli::Config.commands.values.find_all {|c|
        c.usage =~ /cf/
      }
      Bosh::Cli::Command::Help.list_commands(cmds)
    end

    usage "prepare cf"
    desc "upload latest Cloud Foundry release to bosh"
    def prepare_cf
      auth_required

      release_cmd(non_interactive: true).upload(release_yml)
    end

    usage "create cf"
    desc "create a deployment file for Cloud Foundry and deploy it"
    option "--dns mycloud.com", "Primary domain"
    option "--ip 1.2.3.4,1.2.3.5", Array, "Public IPs; one per router node"
    option "--name cf-<timestamp>", "Unique bosh deployment name"
    option "--disk 4096", Integer, "Size of persistent disk (Mb)"
    option "--security-group default", String, "Security group to assign to provisioned VMs"
    option "--deployment-size medium", String, "Size of deployment - medium or large"
    def create_cf
      ip_addresses = options[:ip]
      err("USAGE: bosh create cf --ip 1.2.3.4 -- please provide one IP address that will be bound to router.") if ip_addresses.blank?
      err("Only one IP address is supported currently. Please create an issue to mention you need more.") if ip_addresses.size > 1
      attrs.set(:ip_addresses, ip_addresses)

      dns = options[:dns]
      err("USAGE: bosh create cf --dns mycloud.com -- please provide a base DNS that has a '*' A record referencing IPs") unless dns
      attrs.set(:dns, dns)

      auth_required
      bosh_status # preload

      attrs.set_unless_nil(:name, options[:name])
      attrs.set_unless_nil(:deployment_size, options[:deployment_size])
      attrs.set_unless_nil(:persistent_disk, options[:disk])
      attrs.set_unless_nil(:security_group, options[:security_group])
      attrs.set_unless_nil(:common_password, options[:common_password])

      nl
      say "CPI: #{bosh_cpi.make_green}"
      say "DNS mapping: #{attrs.validated_color(:dns)} --> #{attrs.validated_color(:ip_addresses)}"
      say "Deployment name: #{attrs.validated_color(:name)}"
      say "Resource size: #{attrs.validated_color(:deployment_size)}"
      say "Persistent disk: #{attrs.validated_color(:persistent_disk)}"
      say "Security group: #{attrs.validated_color(:security_group)}"
      nl

      step("Validating deployment size", "Available deployment sizes are #{attrs.available_deployment_sizes.join(', ')}", :non_fatal) do
        attrs.validate(:deployment_size)
      end

      unless confirmed?("Security group #{attrs.validated_color(:security_group)} exists with ports #{attrs.required_ports.join(", ")}")
        cancel_deployment
      end
      unless confirmed?("Creating Cloud Foundry")
        cancel_deployment
      end

      raise Bosh::Cli::ValidationHalted unless errors.empty?

      # Create an initial deployment file; upon which the CPI-specific template will be applied below
      # Initial file will look like:
      # ---
      # name: NAME
      # director_uuid: 4ae3a0f0-70a5-4c0d-95f2-7fafaefe8b9e
      # releases:
      #  - name: cf-release
      #    version: 132
      # networks: {}
      # properties:
      #   cf:
      #     dns: mycloud.com
      #     ip_addresses: ['1.2.3.4']
      #     deployment_size: medium
      #     security_group: cf
      #     persistent_disk: 4096
      step("Checking/creating #{deployment_file_dir} for deployment files",
           "Failed to create #{deployment_file_dir} for deployment files", :fatal) do
        mkdir_p(deployment_file_dir)
      end

      step("Creating deployment file #{deployment_file}",
           "Failed to create deployment file #{deployment_file}", :fatal) do
        File.open(deployment_file, "w") do |file|
          file << {
            "name" => attrs.name,
            "director_uuid" => bosh_uuid,
            "releases" => {
              "name" => release_name,
              "version" => release_version
            },
            "networks" => {},
            "properties" => {
              attrs.properties_key => attrs.attributes_with_string_keys
            }
          }.to_yaml
        end

        quieten_output do
          deployment_cmd(non_interactive: true).set_current(deployment_file)
          biff_cmd(non_interactive: true).biff(template_file)
        end
      end
      # re-set current deployment to show output
      deployment_cmd.set_current(deployment_file)
      deployment_cmd(non_interactive: options[:non_interactive]).perform
    rescue Bosh::Cli::ValidationHalted
      errors.each do |error|
        say error.make_red
      end
    end

    usage "show cf passwords"
    desc "display the internal passwords for deployment"
    def show_cf_passwords
      load_deployment_into_attributes
      say "Common password: #{attrs.validated_color(:common_password)}"
    end

    protected
    # After a deployment is created, the input properties/attributes are stored within the generated
    # deployment file. Therefore, to update a deployment, first we must load in the attributes.
    def load_deployment_into_attributes
      attrs.load_deployment_file(deployment)
    end

    def release_version_cpi_size
      @release_version_cpi_size ||= begin
        Bosh::Cloudfoundry::ReleaseVersionCpiSize.new(release_version, bosh_cpi, deployment_size)
      end
    end

    def template_file
      release_version_cpi_size.template_file_path
    end

    def bosh_release_dir
      File.expand_path("../../../../../bosh_release", __FILE__)
    end

    def latest_release_version
      # the releases/index.yml contains all the available release versions in an unordered
      # hash of hashes in YAML format:
      #     --- 
      #     builds: 
      #       af61f03c5ad6327e0795402f1c458f2fc6f21201: 
      #         version: 3
      #       39c029d0af9effc6913f3333434b894ff6433638: 
      #         version: 1
      #       5f5d0a7fb577fec3c09408c94f7abbe2d52a042c: 
      #         version: 4
      #       f044d47e0183f084db9dac5a6ef00d7bd21c8451: 
      #         version: 2
      release_index = YAML.load_file(File.join(bosh_release_dir, "releases/index.yml"))
      latest_version = release_index["builds"].values.inject(0) do |max_version, release|
        version = release["version"]
        max_version < version ? version : max_version
      end
      latest_version
    end

    def release_yml
      @release_yml ||= begin
        Dir[File.join(bosh_release_dir, "releases", "*-#{latest_release_version}.yml")].first
      end
    end

    def attrs
      @deployment_attributes ||= begin
        klass = release_version_cpi_size.deployment_attributes_class
        klass.new(director_client, bosh_status, release_version_cpi_size)
      end
    end

    # TODO - determined by the release version (appcloud-131, cf-release-132, ...)
    def release_name
      "cf-release"
    end

    # TODO - support other release versions
    def release_version
      132
    end

    def deployment_size
      "medium"
    end

    def director_client
      director
    end

    def deployment_file
      File.join(deployment_file_dir, "#{attrs.name}.yml")
    end

    def deployment_file_dir
      File.expand_path("deployments/cf")
    end

    def deployment_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Deployment.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

    def release_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Release.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

    def biff
      @biff_cmd ||= Bosh::Cli::Command::Biff.new
    end

    def biff_cmd(options = {})
      options.each do |key, value|
        biff.add_option key.to_sym, value
      end
      biff
    end

    def bosh_status
      @bosh_status ||= begin
        step("Fetching bosh information", "Cannot fetch bosh information", :fatal) do
           @bosh_status = director_client.get_status
        end
        @bosh_status
      end
    end

    def bosh_uuid
      bosh_status["uuid"]
    end

    def bosh_cpi
      bosh_status["cpi"]
    end

    def quieten_output(&block)
      stdout = Bosh::Cli::Config.output
      Bosh::Cli::Config.output = nil
      yield
      Bosh::Cli::Config.output = stdout
    end
  end
end
