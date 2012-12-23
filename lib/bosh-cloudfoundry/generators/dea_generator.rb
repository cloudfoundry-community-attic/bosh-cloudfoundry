require 'yaml'
require 'common/properties/property_helper' # bosh_common

module Bosh::CloudFoundry; module Generators; end; end
class Bosh::CloudFoundry::Generators::DeaGenerator < Thor::Group
  include Thor::Actions
  include Bosh::Common::PropertyHelper

  def self.source_root
    File.join(File.dirname(__FILE__), "dea_generator", "templates")
  end

  argument :system_name
  argument :server_count
  argument :server_flavor
  argument :director_uuid
  argument :release_name
  argument :stemcell_version
  argument :resource_pool_cloud_properties
  argument :dea_max_memory
  argument :nats_password

  def deployment_dir
    directory "deployments"
  end

end
