require 'yaml'
require 'common/properties/property_helper' # bosh_common

module Bosh::CloudFoundry; module Generators; end; end
class Bosh::CloudFoundry::Generators::SystemGenerator < Thor::Group
  include Thor::Actions
  include Bosh::Common::PropertyHelper

  def self.source_root
    File.join(File.dirname(__FILE__), "system_generator", "templates")
  end

  argument :system_name
  argument :main_ip
  argument :root_dns

  def deployment_dir
    directory "deployments"
  end

  protected
  #
  # Template methods that need to be implemented
  #
  def director_uuid
    "DIRECTOR_UUID"
  end
  def release_name
    "cf-dev"
  end
  def stemcell_version
    "0.6.4"
  end
  def resource_pool_cloud_properties
    "instance_type: m1.small"
  end
  def persistent_disk
    16192
  end
  def dea_max_memory
    2048
  end
  def admin_email
    "drnic@starkandwayne.com"
  end
  def router_password
    "router1234"
  end
  def nats_password
    "mynats1234"
  end
  def ccdb_password
    "ccdbroot"
  end
end
