module Bosh::Cloudfoundry
  # Each version/CPI/size combination of Cloud Foundry deployment template has
  # input attributes that can or must be provided by a user.
  class DeploymentAttributes
    include BoshExtensions
    include Bosh::Cli::Validation

    attr_reader :attributes
    def initialize(director_client, bosh_status, released_versioned_template, attributes = {})
      @director_client = director_client
      @bosh_status = bosh_status
      @released_versioned_template = released_versioned_template
      @attributes = attributes
      @attributes[:name] = default_name
      @attributes[:size] = default_size
      @attributes[:persistent_disk] = default_persistent_disk
      @attributes[:security_group] = default_security_group
    end

    def name
      @attributes[:name]
    end

    def size
      @attributes[:size]
    end

    def persistent_disk
      @attributes[:persistent_disk]
    end

    def security_group
      @attributes[:security_group]
    end

    def ip_addresses
      @attribute[:ip_addresses]
    end

    def dns
      @attribute[:dns]
    end

    def set_unless_nil(attribute, value)
      attributes[attribute.to_sym] = value if value
    end

    def set(attribute, value)
      attributes[attribute.to_sym] = value if value
    end

    def display_and_validate
      nl
      say "CPI: #{bosh_cpi.make_green}"
      say "DNS mapping: #{validated_color(:dns)} --> #{validated_color(:ip_addresses)}"
      say "Deployment name: #{validated_color(:name)}"
      say "Resource size: #{validated_color(:size)}"
      say "Persistent disk: #{validated_color(:persistent_disk)}"
      say "Security group: #{validated_color(:security_group)}"
      nl

      step("Validating resource size", "Resource size must be in #{available_resource_sizes.join(', ')}", :non_fatal) do
        available_resource_sizes.include?(size)
      end

      unless confirmed?("Security group exists with ports #{required_ports.join(", ")}")
        cancel_deployment
      end
      unless confirmed?("Creating Cloud Foundry")
        cancel_deployment
      end

      raise Bosh::Cli::ValidationHalted unless errors.empty?
    end

    def validate(attribute)
      value = attributes[attribute.to_sym]
      if attribute.to_s =~ /size$/
        available_resource_sizes.include?(value)
      else
        true
      end
    end

    def format(attribute)
      value = attributes[attribute.to_sym].to_s
    end

    def validated_color(attribute)
      validate(attribute) ?
        format(attribute).make_green :
        format(attribute).make_red
    end

    # TODO move these validations into a "ValidatedSize" class or similar
    def available_resource_sizes
      resources = @released_versioned_template.spec["resources"]
      if resources && resources.is_a?(Array) && resources.first.is_a?(String)
        resources
      else
        err "template spec needs 'resources' key with list of resource pool names available"
      end
    end

    # If using security groups, the following ports must be opened for external access:
    # * 22 - ssh to all servers
    # * 80 - http traffic to routers
    # * 443 - https traffic to routers
    # * 4222 - access to nats server
    def required_ports
      [22, 80, 443, 4222]
    end


    private
    def default_name
      "cf-#{Time.now.to_i}"
    end

    def default_size
      "small"
    end

    def default_persistent_disk
      4096
    end

    def default_security_group
      "default"
    end

    def bosh_uuid
      @bosh_status["uuid"]
    end

    def bosh_cpi
      @bosh_status["cpi"]
    end

  end
end