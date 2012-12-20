require 'yaml'
require 'thor/group'
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

  def deployment_manifests
    directory "deployments"
  end
end
