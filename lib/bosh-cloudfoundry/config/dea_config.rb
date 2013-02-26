# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

class Bosh::CloudFoundry::Config::DeaConfig
  attr_reader :system_config

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
    self.dea_server_count = server_count.to_i
    self.dea_server_flavor = server_flavor.to_s
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

  # Adds additional cf-release jobs into the core server (the core job in the manifest)
  def add_core_jobs_to_manifest(manifest)
    if dea_server_count == 0
      @core_job ||= manifest["jobs"].find { |job| job["name"] == "core" }
      @core_job["template"] << "dea"
    end
  end

  # Adds resource pools to the target manifest, if dea_server_count > 0
  #
  # - name: dea
  #   network: default
  #   size: 2
  #   stemcell: 
  #     name: bosh-stemcell
  #     version: 0.7.0
  #   cloud_properties: 
  #     instance_type: m1.xlarge
  def add_resource_pools_to_manifest(manifest)
    if dea_server_count > 0
      resource_pool = {
        "name" => "dea",
        "network" => "default",
        "size" => dea_server_count,
        "stemcell" => {
          "name" => @system_config.stemcell_name,
          "version" => @system_config.stemcell_version
        },
        # TODO how to create "cloud_properties" per-provider?
        "cloud_properties" => {
          "instance_type" => dea_server_flavor
        }
      }
      manifest["resource_pools"] << resource_pool
    end
  end

  # Jobs to add to the target manifest
  #
  # - name: dea
  #   template: 
  #   - dea
  #   instances: 2
  #   resource_pool: dea
  #   networks: 
  #   - name: default
  #     default: 
  #     - dns
  #     - gateway
  def add_jobs_to_manifest(manifest)
    if dea_server_count > 0
      job = {
        "name" => "dea",
        "template" => ["dea"],
        "instances" => dea_server_count,
        "resource_pool" => "dea",
        # TODO are these AWS-specific networks?
        "networks" => [{
          "name" => "default",
          "default" => ["dns", "gateway"]
        }]
      }
      manifest["jobs"] << job
    end
  end

  # Add extra configuration properties into the manifest
  # to configure the allocation of RAM to the DEA
  def merge_manifest_properties(manifest)
    manifest["properties"]["dea"] ||= {}
    manifest["properties"]["dea"] = {
      "max_memory" => max_memory
    }
  end

  # The RAM for a dedicated DEA node
  # else the RAM of the core/0 VM
  # minus the +preallocated_ram+.
  def max_memory
    if dea_server_count > 0
      max_memory_for_dedicated_dea
    else
      dea_ram_for_core_vm_flavor
    end
  end

  # @return [Integer] available ram for running CloudFoundry apps
  def max_memory_for_dedicated_dea
    ram_for_server_flavor - preallocated_ram
  end

  # @return [Integer] the ballpark ram for DEA, BOSH agent, etc
  def preallocated_ram
    300
  end

  def dea_ram_for_core_vm_flavor
    ram_for_core_vm_flavor - preallocated_ram
  end

  def ram_for_core_vm_flavor
    provider.ram_for_server_flavor(system_config.core_server_flavor)
  end

  def ram_for_server_flavor
    provider.ram_for_server_flavor(dea_server_flavor)
  end

  # a helper object for the target BOSH provider
  def provider
    @provider ||= Bosh::CloudFoundry::Providers.for_bosh_provider_name(system_config)
  end
end