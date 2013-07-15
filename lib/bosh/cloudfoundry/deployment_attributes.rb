module Bosh::Cloudfoundry
  # Each version/CPI/size combination of Cloud Foundry deployment template has
  # input attributes that can or must be provided by a user.
  class DeploymentAttributes
    include BoshExtensions
    include Bosh::Cli::Validation

    attr_reader :attributes
    attr_reader :released_version_cpi

    def initialize(director_client, bosh_status, released_version_cpi, attributes = {})
      @director_client = director_client
      @bosh_status = bosh_status
      @released_version_cpi = released_version_cpi
      @attributes = attributes
      @attributes[:name] ||= default_name
      @attributes[:deployment_size] ||= default_deployment_size
      @attributes[:persistent_disk] ||= default_persistent_disk
      @attributes[:security_group] ||= default_security_group
      @attributes[:common_password] ||= random_string(12, :common)
    end

    def name
      @attributes[:name]
    end

    def deployment_size
      @attributes[:deployment_size]
    end

    def persistent_disk
      @attributes[:persistent_disk]
    end

    def security_group
      @attributes[:security_group]
    end

    def ip_addresses
      @attributes[:ip_addresses]
    end

    def dns
      @attributes[:dns]
    end

    def set_unless_nil(attribute, value)
      attributes[attribute.to_sym] = value if value
    end

    def set(attribute, value)
      attributes[attribute.to_sym] = value if value
    end

    def load_deployment_file(deployment_file)
      deployment_obj = YAML.load_file(deployment_file)
      attributes = deployment_obj["properties"][properties_key]
      @attributes = attributes.inject({}) do |mem, key_value|
        k, v = key_value; mem[k.to_sym] = v; mem
      end
    end

    def validate(attribute)
      value = attributes[attribute.to_sym]
      if attribute.to_s == "deployment_size"
        available_deployment_sizes.include?(value)
      elsif attribute.to_s =~ /size$/
        available_resources.include?(value)
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
    def available_resources
      @available_resources ||= begin
        resources = released_version_cpi.spec["resources"]
        if resources && resources.is_a?(Array) && resources.first.is_a?(String)
          resources
        else
          err "template spec needs 'resources' key with list of resource pool names available; found #{released_version_cpi.spec.inspect}"
        end
      end
    end

    def available_deployment_sizes
      @available_deployment_sizes ||= begin
        deployment_sizes = released_version_cpi.spec["deployment_sizes"]
        if deployment_sizes && deployment_sizes.is_a?(Array) && deployment_sizes.first.is_a?(String)
          deployment_sizes
        else
          err "template spec needs 'deployment_sizes' key with list of deployment sizes names available; found #{deployment_sizes.spec.inspect}"
        end
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

    def attributes_with_string_keys
      attributes.inject({}) do |mem, key_value|
        key, value = key_value
        mem[key.to_s] = value
        mem
      end
    end

    private
    def default_name
      "cf-#{Time.now.to_i}"
    end

    # TODO change to small when its implemented
    def default_deployment_size
      "medium"
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

    # Generate a random string for passwords and tokens.
    # Length is the length of the string.
    # name is an optional name of a previously generated string. This is used
    # to allow setting the same password for different components.
    # Extracted from Bosh::Cli::Command::Biff
    def random_string(length, name=nil)
      random_string = SecureRandom.hex(length)[0...length]

      @random_cache ||= {}
      if name
        @random_cache[name] ||= random_string
      else
        random_string
      end
    end

  end
end