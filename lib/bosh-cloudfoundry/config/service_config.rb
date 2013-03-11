# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

class Bosh::CloudFoundry::Config::ServiceConfig
  attr_reader :system_config

  def initialize(system_config)
    @system_config = system_config
  end

  def self.build_from_system_config(system_config)
    new(system_config)
  end

  # name that maps into the cf-release's jobs folder
  # for xyz_gateway and xyz_node jobs
  def service_name
    raise "please implement #service_name in your subclass #{self.class}"
  end

  # the subset of SystemConfig that describes this ServiceConfig;
  # by default, assume its in a key of the +service_name+
  def config
    system_config.send(service_name.to_sym) || []
  end

  def bosh_provider_name
    system_config.bosh_provider
  end

  def job_gateway_name
    "#{service_name}_gateway"
  end

  def job_node_name
    "#{service_name}_node"
  end

  # resource_pool name for a cluster
  # cluster_name like 'redis_m1_xlarge_free'
  def cluster_name(cluster)
    server_flavor = cluster["flavor"]
    server_plan = cluster["plan"] || "free"
    cluster_name = "#{service_name}_#{server_flavor}_#{server_plan}"
    cluster_name.gsub!(/\W+/, '_')
    cluster_name
  end

  # @return [Boolean] true if there are any postgresql nodes to be provisioned
  def any_service_nodes?
    total_service_nodes_count > 0
  end

  def total_service_nodes_count
    config.inject(0) { |total, cluster| total + (cluster["count"].to_i) }
  end

  def update_cluster_count_for_flavor(server_count, server_flavor, server_plan="free")
    if cluster = find_cluster_for_flavor(server_flavor.to_s)
      cluster["count"] = server_count
    else
      config << {"count" => server_count, "flavor" => server_flavor.to_s, "plan" => server_plan}
    end
    self.save
  end

  # @return [Hash] the Hash from system_config for the requested flavor
  # nil if its not currently a requested flavor
  def find_cluster_for_flavor(server_flavor)
    config.find { |cl| cl["flavor"] == server_flavor }
  end

  def save
    system_config.save
  end

  # @return [Integer] the ballpark ram for redis, BOSH agent, etc
  def preallocated_ram
    300
  end

  def ram_for_server_flavor
    provider.ram_for_server_flavor(server_flavor)
  end

  # a helper object for the target BOSH provider
  def provider
    @provider ||= Bosh::CloudFoundry::Providers.for_bosh_provider_name(system_config)
  end

  def build_into_manifest(manifest)
    add_core_jobs_to_manifest(manifest)
    add_resource_pools_to_manifest(manifest)
    add_jobs_to_manifest(manifest)
    merge_manifest_properties(manifest)
  end

  # Adds "redis_gateway" to colocated "core" job
  def add_core_jobs_to_manifest(manifest)
    if any_service_nodes?
      @core_job ||= manifest["jobs"].find { |job| job["name"] == "core" }
      @core_job["template"] << job_gateway_name
    end
  end

  # Adds resource pools to the target manifest, if server_count > 0
  #
  # - name: redis
  #   network: default
  #   size: 2
  #   stemcell: 
  #     name: bosh-stemcell
  #     version: 0.7.0
  #   cloud_properties: 
  #     instance_type: m1.xlarge
  def add_resource_pools_to_manifest(manifest)
    if any_service_nodes?
      config.each do |cluster|
        server_count = cluster["count"]
        server_flavor = cluster["flavor"]
        resource_pool = {
          "name" => cluster_name(cluster),
          "network" => "default",
          "size" => server_count,
          "stemcell" => {
            "name" => system_config.stemcell_name,
            "version" => system_config.stemcell_version
          },
          # TODO how to create "cloud_properties" per-provider?
          "cloud_properties" => {
            "instance_type" => server_flavor
          },
          "persistent_disk" => system_config.common_persistent_disk
        }
        manifest["resource_pools"] << resource_pool
      end
    end
  end

  # Jobs to add to the target manifest
  #
  # - name: redis
  #   template: 
  #   - redis
  #   instances: 2
  #   resource_pool: redis
  #   networks: 
  #   - name: default
  #     default: 
  #     - dns
  #     - gateway
  def add_jobs_to_manifest(manifest)
    if any_service_nodes?
      config.each do |cluster|
        server_count = cluster["count"]
        server_flavor = cluster["flavor"]
        job = {
          "name" => cluster_name(cluster),
          "template" => [job_node_name],
          "instances" => server_count,
          "resource_pool" => cluster_name(cluster),
          # TODO are these AWS-specific networks?
          "networks" => [{
            "name" => "default",
            "default" => ["dns", "gateway"]
          }],
          "persistent_disk" => system_config.common_persistent_disk
        }
        manifest["jobs"] << job
      end
    end
  end

end