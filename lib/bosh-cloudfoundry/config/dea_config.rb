# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

class Bosh::CloudFoundry::Config::DeaConfig

  def initialize(system_config)
    @system_config = system_config
  end

  def self.build_from_system_config(system_config)
    system_config.dea ||= {}
    new(system_config)
  end

  def bosh_provider_name
    @system_config.bosh_provider
  end

  def update_count_and_flavor(server_count, server_flavor)
    self.dea_server_count = server_count
    self.dea_server_flavor = server_flavor
    self.save
  end

  # Determine ow many DEA servers are required
  # based on the system configuration
  def dea_server_count
    @system_config.dea["count"] || 0
  end

  def dea_server_count=(count)
    @system_config.dea["count"] = count
  end

  def dea_server_flavor
    @system_config.dea["flavor"]
  end

  def dea_server_flavor=(flavor)
    @system_config.dea["flavor"] = flavor
  end

  def save
    @system_config.save
  end

  # @returns [Array] of strings representing 0+ job templates to
  # include in the "core" server of colocated jobs in the
  # generated deployment manifest
  def jobs_to_add_to_core_server
    if dea_server_count == 0
      %w[dea]
    else
      []
    end
  end

  def deployment_manifest_properties
    {
      "dea" => {
        "max_memory" => max_memory
      }
    }
  end

  def max_memory
    if dea_server_count == 0
      512
    else
      max_memory_for_dedicated_dea
    end
  end

  # @returns [Integer] available ram for running CloudFoundry apps
  def max_memory_for_dedicated_dea
    ram_for_server_flavor - preallocated_ram
  end

  # @returns [Integer] the ballpark ram for DEA, BOSH agent, etc
  def preallocated_ram
    300
  end

  def ram_for_server_flavor
    provider.ram_for_server_flavor(dea_server_flavor)
  end

  # a helper object for the target BOSH provider
  def provider
    @provider ||= Bosh::CloudFoundry::Providers.for_bosh_provider_name(bosh_provider_name)
  end
end