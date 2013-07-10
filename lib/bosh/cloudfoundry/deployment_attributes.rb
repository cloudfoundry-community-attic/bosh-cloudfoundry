module Bosh::Cloudfoundry
  # Each version/CPI/size combination of Cloud Foundry deployment template has
  # input attributes that can or must be provided by a user.
  class DeploymentAttributes
    attr_reader :attributes
    def initialize(attributes = {})
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

    def set_unless_nil(attribute, value)
      attributes[attribute.to_sym] = value if value
    end

    def validated_color(attribute)
      attributes[attribute.to_sym].to_s.make_green
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
  end
end