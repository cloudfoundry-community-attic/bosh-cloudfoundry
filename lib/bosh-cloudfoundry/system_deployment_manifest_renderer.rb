# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# Renders a +SystemConfig+ model into a System's BOSH deployment
# manifest(s).
class Bosh::CloudFoundry::SystemDeploymentManifestRenderer
  include FileUtils
  attr_reader :system_config, :common_config, :bosh_config

  def initialize(system_config, common_config, bosh_config)
    @system_config = system_config
    @common_config = common_config
    @bosh_config = bosh_config
  end

  # Render deployment manifest(s) for a system
  # based on the model data in +system_config+
  # (a +SystemConfig+ object).
  def perform
    validate_system_config

    director_uuid = bosh_config.target_uuid
    system_name = system_config.system_name
    release_name = system_config.release_name
    stemcell_version = system_config.stemcell_version
    core_cloud_properties = cloud_properties_for_server_flavor(system_config.core_server_flavor)
    core_ip = system_config.core_ip
    root_dns = system_config.root_dns
    persistent_disk = 16192
    dea_max_memory = 2048
    admin_email = "drnic@starkandwayne.com"
    router_password = "router1234"
    nats_password = "mynats1234"
    ccdb_password = "ccdbroot"
    chdir system_config.system_dir do
      require 'bosh-cloudfoundry/generators/new_system_generator'
      Bosh::CloudFoundry::Generators::NewSystemGenerator.start([
        system_name, core_ip, root_dns,
        director_uuid, release_name, stemcell_version,
        core_cloud_properties, persistent_disk,
        dea_max_memory,
        admin_email,
        router_password, nats_password, ccdb_password])
    end
  end

  def validate_system_config
    s = system_config
    must_not_be_nil = [
      :bosh_provider,
      :release_name,
      :stemcell_version,
      :core_server_flavor,
      :system_dir,
      :core_ip,
      :root_dns
    ]
    must_not_be_nil_failures = must_not_be_nil.inject([]) do |list, attribute|
      list << attribute unless system_config.send(attribute)
      list
    end
    if must_not_be_nil_failures.size > 0
      raise "These SystemConfig fields must not be nil: #{must_not_be_nil_failures.inspect}"
    end
  end

  # Converts a server flavor (such as 'm1.large' on AWS) into
  # a BOSH deployment manifest +cloud_properties+ YAML string
  # For AWS & m1.large, it would be:
  #   'instance_type: m1.large'
  def cloud_properties_for_server_flavor(server_flavor)
    if aws?
      "instance_type: #{server_flavor}"
    else
      raise 'Please implement #{self.class}#cloud_properties_for_server_flavor'
    end
  end

  def aws?
    system_config.bosh_provider == "aws"
  end
end
