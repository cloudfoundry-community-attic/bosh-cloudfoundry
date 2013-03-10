# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

module Bosh::CloudFoundry::Config
  class RedisServiceConfig < ServiceConfig

    # name that maps into the cf-release's jobs folder
    # for redis_gateway and redis_node jobs
    def service_name
      "redis"
    end

    # Add extra configuration properties into the manifest
    # for the gateway, node, and service plans
    def merge_manifest_properties(manifest)
      if any_service_nodes?
        manifest["properties"]["redis_gateway"] = {
          "token"=>"TOKEN",
          "supported_versions"=>["2.2"],
          "version_aliases"=>{"current"=>"2.2"}
        }
        manifest["properties"]["redis_node"] = {
          "available_memory"=>256,
          "supported_versions"=>["2.2"],
          "default_version"=>"2.2"
        }
        manifest["properties"]["service_plans"]["redis"] = {
          "free"=>
           {"job_management"=>{"high_water"=>1400, "low_water"=>100},
            "configuration"=>
             {"capacity"=>200,
              "max_memory"=>16,
              "max_swap"=>32,
              "max_clients"=>500,
              "backup"=>{"enable"=>true}}}
        }
      end
    end
  end
end