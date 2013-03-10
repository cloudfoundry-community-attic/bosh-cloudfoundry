# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

module Bosh::CloudFoundry::Config
  class PostgresqlServiceConfig < ServiceConfig

    # name that maps into the cf-release's jobs folder
    # for postgresql_gateway and postgresql_node jobs
    # also used as the key into SystemConfig manifest
    def service_name
      "postgresql"
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
  end
end