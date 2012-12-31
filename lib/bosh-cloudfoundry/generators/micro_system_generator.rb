require 'yaml'
require 'common/properties/property_helper' # bosh_common

module Bosh::CloudFoundry; module Generators; end; end
class Bosh::CloudFoundry::Generators::MicroSystemGenerator < Thor::Group
  include Thor::Actions
  include Bosh::Common::PropertyHelper

  def self.source_root
    File.join(File.dirname(__FILE__), "micro_system_generator", "templates")
  end

  argument :system_name
  argument :main_ip
  argument :root_dns
  argument :director_uuid
  argument :release_name
  argument :stemcell_version
  argument :resource_pool_cloud_properties
  argument :persistent_disk
  argument :dea_max_memory
  argument :admin_email
  argument :router_password
  argument :nats_password
  argument :ccdb_password

  def deployment_dir
    directory "deployments"
  end

  def deployment_name
    "{system_name}-micro"
  end
end
