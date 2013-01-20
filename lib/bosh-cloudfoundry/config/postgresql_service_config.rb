# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

class Bosh::CloudFoundry::Config::PostgresqlServiceConfig

  def initialize(system_config)
    @system_config = system_config
  end

  def self.build_from_system_config(system_config)
    system_config.postgresql ||= []
    new(system_config)
  end

  def config
    @system_config.postgresql
  end

  # @return [Boolean] true if there are any postgresql nodes to be provisioned
  def any_service_nodes?
    total_service_nodes_count > 0
  end

  def total_service_nodes_count
    config.inject(0) { |total, cluster| total + (cluster["count"].to_i) }
  end

  def bosh_provider_name
    @system_config.bosh_provider
  end

  def update_cluster_count_for_flavor(server_count, server_flavor, server_plan="free")
    if cluster = find_cluster_for_flavor(server_flavor.to_s)
      cluster["count"] = server_count
    else
      config << {"count" => server_count, "flavor" => server_flavor.to_s, "plan" => server_plan}
    end
    self.save
  end

  # @return [Hash] the Hash from @system_config for the requested flavor
  # nil if its not currently a requested flavor
  def find_cluster_for_flavor(server_flavor)
    @system_config.postgresql.find { |cl| cl["flavor"] == server_flavor }
  end

  def save
    @system_config.save
  end

  # resource_pool name for a cluster
  # cluster_name like 'postgresql_m1_xlarge_free'
  def cluster_name(cluster)
    server_flavor = cluster["flavor"]
    server_plan = cluster["plan"] || "free"
    cluster_name = "postgresql_#{server_flavor}_#{server_plan}"
    cluster_name.gsub!(/\W+/, '_')
    cluster_name
  end

  # Adds "postgresql_gateway" to colocated "core" job
  def add_core_jobs_to_manifest(manifest)
    if any_service_nodes?
      @core_job ||= manifest["jobs"].find { |job| job["name"] == "core" }
      @core_job["template"] << "postgresql_gateway"
    end
  end

  # Adds resource pools to the target manifest, if server_count > 0
  #
  # - name: postgresql
  #   network: default
  #   size: 2
  #   stemcell: 
  #     name: bosh-stemcell
  #     version: 0.6.4
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
            "name" => @system_config.stemcell_name,
            "version" => @system_config.stemcell_version
          },
          # TODO how to create "cloud_properties" per-provider?
          "cloud_properties" => {
            "instance_type" => server_flavor
          },
          "persistent_disk" => 16192
        }
        manifest["resource_pools"] << resource_pool
      end
    end
  end

  # Jobs to add to the target manifest
  #
  # - name: postgresql
  #   template: 
  #   - postgresql
  #   instances: 2
  #   resource_pool: postgresql
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
          "template" => ["postgresql_node"],
          "instances" => server_count,
          "resource_pool" => cluster_name(cluster),
          # TODO are these AWS-specific networks?
          "networks" => [{
            "name" => "default",
            "default" => ["dns", "gateway"]
          }],
          "persistent_disk" => 16192
        }
        manifest["jobs"] << job
      end
    end
  end

  # Add extra configuration properties into the manifest
  # for the gateway, node, and service plans
  def merge_manifest_properties(manifest)
    if any_service_nodes?
      manifest["properties"]["postgresql_gateway"] = {
        "admin_user"=>"psql_admin",
        "admin_passwd_hash"=>nil,
        "token"=>"TOKEN",
        "supported_versions"=>["9.0"],
        "version_aliases"=>{"current"=>"9.0"}
      }
      manifest["properties"]["postgresql_node"] = {
        "admin_user"=>"psql_admin",
        "admin_passwd_hash"=>nil,
        "available_storage"=>2048,
        "max_db_size"=>256,
        "max_long_tx"=>30,
        "supported_versions"=>["9.0"],
        "default_version"=>"9.0"
      }
      manifest["properties"]["service_plans"]["postgresql"] = {
        "free"=>
         {"job_management"=>{"high_water"=>1400, "low_water"=>100},
          "configuration"=>
           {"capacity"=>200,
            "max_db_size"=>128,
            "max_long_query"=>3,
            "max_long_tx"=>30,
            "max_clients"=>20,
            "backup"=>{"enable"=>true}}}
      }
    end
  end

  # @return [Integer] the ballpark ram for postgresql, BOSH agent, etc
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
end