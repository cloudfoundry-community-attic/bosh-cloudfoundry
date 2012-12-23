require 'yaml'
require 'common/properties/property_helper' # bosh_common

module Bosh::CloudFoundry; module Generators; end; end
class Bosh::CloudFoundry::Generators::ServiceGenerator < Thor::Group
  include Thor::Actions
  include Bosh::Common::PropertyHelper

  def self.source_root
    File.join(File.dirname(__FILE__), "service_generator", "templates")
  end

  argument :system_name
  argument :service_name
  argument :service_server_count
  argument :service_server_flavor
  argument :director_uuid
  argument :release_name
  argument :stemcell_version
  argument :resource_pool_cloud_properties
  argument :persistent_disk
  argument :nats_password

  def deployment_dir
    directory "#{service_name}/deployments", "deployments"
  end

end
