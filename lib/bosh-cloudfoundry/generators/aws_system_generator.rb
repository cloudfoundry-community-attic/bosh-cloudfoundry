require 'yaml'
require 'common/properties/property_helper' # bosh_common

module Bosh::CloudFoundry; module Generators; end; end
class Bosh::CloudFoundry::Generators::NewSystemGenerator < Thor::Group
  include Thor::Actions
  include Bosh::Common::PropertyHelper

  def self.source_root
    File.join(File.dirname(__FILE__), "aws_system_generator", "templates")
  end

  argument :system_name
  argument :core_ip
  argument :root_dns
  argument :director_uuid
  argument :release_name
  argument :stemcell_version
  argument :resource_pool_cloud_properties
  argument :persistent_disk
  argument :dea_max_memory
  argument :admin_email
  argument :common_password
  argument :security_group

  def deployment_dir
    directory "deployments"
  end

  protected
  def deployment_name
    "#{system_name}-core"
  end

  def bosh_provider
    "aws"
  end

  def dea_max_memory
    512
  end
end
