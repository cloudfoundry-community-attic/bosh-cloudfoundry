require "yaml"

# for the #sh helper
require "rake"
require "rake/file_utils"

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

    usage "create cf"
    desc "create a deployment file for Cloud Foundry and deploy it"
    option "--dns mycloud.com", "Primary domain"
    option "--ip 1.2.3.4,1.2.3.5", Array, "Public IPs; one per router node"
    option "--name cf-<timestamp>", "Unique bosh deployment name"
    option "--size small", "Resource size of core server"
    option "--disk 4096", Integer, "Size of persistent disk (Mb)"
    option "--security-group default", String, "Security group to assign to provisioned VMs"
    def create_cf
      ip_addresses = options[:ip]
      err("USAGE: bosh create cf --ip 1.2.3.4 -- please provide one IP address that will be bound to router.") if ip_addresses.blank?
      err("Only one IP address is supported currently. Please create an issue to mention you need more.") if ip_addresses.size > 1

      dns = options[:dns]
      err("USAGE: bosh create cf --dns mycloud.com -- please provide a base DNS that has a '*' A record referencing IPs") unless dns

      auth_required

      attrs.set_unless_nil(:name, options[:name])
      attrs.set_unless_nil(:size, options[:size])
      attrs.set_unless_nil(:persistent_disk, options[:disk])
      attrs.set_unless_nil(:security_group, options[:security_group])

      bosh_status # preload
      nl
      say "CPI: #{bosh_cpi.make_green}"
      say "Deployment name: #{attrs.validated_color(:name)}"
      say "Resource size: #{attrs.validated_color(:size)}"
      say "Persistent disk: #{attrs.validated_color(:persistent_disk)}"
      say "Security group: #{attrs.validated_color(:security_group)}"
      nl


    end

    protected
    def release_versioned_template
      @release_versioned_template ||= Bosh::Cloudfoundry::ReleaseVersionedTemplate.new(release_version, bosh_cpi, deployment_size)
    end

    def attrs
      @deployment_attributes ||= release_versioned_template.deployment_attributes_class.new
    end

    # TODO - support other deployment sizes
    def release_version
      132
    end

    # TODO - support other deployment sizes
    def deployment_size
      "dev"
    end

    def bosh_release_spec
      release_versioned_template.spec
    end

    def available_resource_sizes
      resources = bosh_release_spec["resources"]
      if resources && resources.is_a?(Array) && resources.first.is_a?(String)
        resources
      else
        err "template spec needs 'resources' key with list of resource pool names available"
      end
    end

    # If resource_size is within +available_resource_sizes+ then display it in green;
    # else display it in red.
    def validated_resource_size_colored(resource_size)
      available_resource_sizes.include?(resource_size) ?
        resource_size.make_green : resource_size.make_red
    end

    def bosh_status
      @bosh_status ||= begin
        step("Fetching bosh information", "Cannot fetch bosh information", :fatal) do
           @bosh_status = bosh_director_client.get_status
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

    def bosh_director_client
      director
    end
  end
end
