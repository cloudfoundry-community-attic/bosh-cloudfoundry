# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

class Bosh::CloudFoundry::Config::DeaConfig
  attr_reader :count, :flavor

  def initialize(count, flavor, bosh_provider_name)
    @count, @flavor, @bosh_provider_name = count, flavor, bosh_provider_name
  end

  def self.build_from_system_config(system_config)
    bosh_provider = system_config.bosh_provider
    if dea_config = system_config.dea
      count = dea_config["count"] || dea_config[:count]
      flavor = dea_config["flavor"] || dea_config[:flavor]
    else
      count = 0
      flavor = nil
    end
    new(count, flavor, bosh_provider)
  end

  # Determine ow many DEA servers are required
  # based on the system configuration
  def dea_server_count
    @count
  end

  # @returns [Array] of strings representing 0+ job templates to
  # include in the "core" server of colocated jobs in the
  # generated deployment manifest
  def jobs_to_add_to_core_server
    if @count == 0
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
    if @count == 0
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
    provider.ram_for_server_flavor(flavor)
  end

  # a helper object for the target BOSH provider
  def provider
    @provider ||= Bosh::CloudFoundry::Providers.for_bosh_provider_name(@bosh_provider_name)
  end
end