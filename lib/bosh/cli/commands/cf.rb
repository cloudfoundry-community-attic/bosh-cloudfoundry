require "yaml"
require "bosh/cloudfoundry"

module Bosh::Cli::Command
  class CloudFoundry < Base
    include FileUtils
    include Bosh::Cli::Validation
    include Bosh::Cloudfoundry

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
      bosh_status # preload

      release_yml = Dir[File.join(bosh_release_dir, "releases", "*-#{latest_release_version}.yml")].first
      release_cmd(non_interactive: true).upload(release_yml)

      stemcell_url = "http://bosh-jenkins-artifacts.s3.amazonaws.com/bosh-stemcell/#{bosh_cpi}/latest-bosh-stemcell-#{bosh_cpi}.tgz"
      stemcell_cmd(non_interactive: true).upload(stemcell_url)
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
      auth_required
      bosh_status # preload

      setup_deployment_attributes

      ip_addresses = options[:ip]
      err("USAGE: bosh create cf --ip 1.2.3.4 -- please provide one IP address that will be bound to router.") if ip_addresses.blank?
      err("Only one IP address is supported currently. Please create an issue to mention you need more.") if ip_addresses.size > 1
      attrs.set(:ip_addresses, ip_addresses)

      dns = options[:dns]
      err("USAGE: bosh create cf --dns mycloud.com -- please provide a base DNS that has a '*' A record referencing IPs") unless dns
      attrs.set(:dns, dns)

      attrs.set_unless_nil(:name, options[:name])
      attrs.set_unless_nil(:persistent_disk, options[:disk])
      attrs.set_unless_nil(:security_group, options[:security_group])
      attrs.set_unless_nil(:common_password, options[:common_password])
      attrs.set_unless_nil(:deployment_size, options[:deployment_size])

      release_version = ReleaseVersion.latest_version_number
      @release_version_cpi_size = 
        ReleaseVersionCpiSize.new(@release_version_cpi, attrs.deployment_size)

      nl
      say "CPI: #{bosh_cpi.make_green}"
      say "DNS mapping: #{attrs.validated_color(:dns)} --> #{attrs.validated_color(:ip_addresses)}"
      say "Deployment name: #{attrs.validated_color(:name)}"
      say "Deployment size: #{attrs.validated_color(:deployment_size)}"
      say "Persistent disk: #{attrs.validated_color(:persistent_disk)}"
      say "Security group: #{attrs.validated_color(:security_group)}"
      nl

      step("Validating deployment size", "Available deployment sizes are #{attrs.available_deployment_sizes.join(', ')}", :fatal) do
        attrs.validate(:deployment_size)
      end

      validate_dns_mapping

      unless confirmed?("Security group #{attrs.validated_color(:security_group)} exists with ports #{attrs.required_ports.join(", ")}")
        cancel_deployment
      end
      unless confirmed?("Creating Cloud Foundry")
        cancel_deployment
      end

      raise Bosh::Cli::ValidationHalted unless errors.empty?

      deployment_file = DeploymentFile.new(@release_version_cpi_size, attrs, bosh_status)
      deployment_file.prepare_environment
      deployment_file.create_deployment_file
      deployment_file.deploy(options)

    rescue Bosh::Cli::ValidationHalted
      errors.each do |error|
        say error.make_red
      end
    end

    usage "show cf properties"
    desc "display the deployment properties, indicate which are changable"
    def show_cf_properties
      setup_deployment_attributes
      reconstruct_deployment_file
      nl
      say "Immutable properties:"
      attrs.immutable_attributes.each do |attr_name|
        say "#{attr_name}: #{attrs.validated_color(attr_name.to_sym)}"
      end
      nl
      say "Mutable (changable) properties:"
      attrs.mutable_attributes.each do |attr_name|
        say "#{attr_name}: #{attrs.validated_color(attr_name.to_sym)}"
      end
    end

    usage "change cf properties"
    desc "change deployment properties and perform bosh deploy"
    def change_cf_properties(*key_value)
      setup_deployment_attributes
      reconstruct_deployment_file
      
    end

    protected
    def setup_deployment_attributes
      @release_version_cpi = ReleaseVersionCpi.latest_for_cpi(bosh_cpi)
      @deployment_attributes = DeploymentAttributes.new(director_client, bosh_status, @release_version_cpi)
    end

    def attrs
      @deployment_attributes
    end

    # After a deployment is created, the input properties/attributes are stored within the generated
    # deployment file. Therefore, to update a deployment, first we must load in the attributes.
    def reconstruct_deployment_file
      @deployment_file = DeploymentFile.reconstruct_from_deployment_file(deployment, director_client, bosh_status)
      @deployment_attributes = @deployment_file.deployment_attributes
      @release_version_cpi_size = @deployment_file.release_version_cpi_size
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

    def director_client
      director
    end

    def bosh_status
      @bosh_status ||= begin
        step("Fetching bosh information", "Cannot fetch bosh information", :fatal) do
           @bosh_status = director_client.get_status
        end
        @bosh_status
      end
    end

    def bosh_cpi
      bosh_status["cpi"]
    end

    # TODO move into PrepareBosh class
    def release_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Release.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

    def stemcell_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Stemcell.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

    def validate_dns_mapping
      attrs.validate_dns_mapping
    end
  end
end
