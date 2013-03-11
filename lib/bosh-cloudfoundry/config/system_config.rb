# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

# Model for the configuration data of a CloudFoundry System
# description.
# Stores the data as a YAML configuration file within a System's
# home folder.
class Bosh::CloudFoundry::Config::SystemConfig < Bosh::Cli::Config

  # Defaults the +system_dir+ and +system_name+ based on the path
  # of the +config_file+.
  # It is assumed that the +config_file+ is located within a folder
  # dedicated to the System begin configured.
  def initialize(system_dir)
    config_file      = File.join(system_dir, "manifest.yml")
    super(config_file, system_dir)
    self.system_dir  = system_dir
    self.system_name = File.basename(system_dir)
    setup_services
  end

  def self.create_config_accessor(attr)
    define_method attr do
      read(attr, false)
    end

    define_method "#{attr}=" do |value|
      write_global(attr, value)
    end
  end

  # Accessors for access to config manifest
  # Additional accessors are created for each service, such as redis/redis= & postgresql/postgresql=
  [
    :bosh_target,      # e.g. http://1.2.3.4:25555
    :bosh_target_uuid,
    :bosh_provider,    # from list 'aws', 'openstack', 'vsphere', 'vcloud'
    :system_name,      # e.g. production
    :system_dir,       # e.g. /var/vcap/store/systems/production
    :cf_release_git_repo, # e.g. "git://github.com/cloudfoundry/cf-release.git"
    :cf_release_dir,   # e.g. /var/vcap/store/releases/cf-release
    :cf_release_branch,     # e.g. staging
    :cf_release_branch_dir, # e.g. /var/vcap/store/releases/cf-release/staging
    :release_name,     # e.g. 'appcloud'
    :release_type,     # either 'final' or 'dev'
    :release_version,  # e.g. 'latest'
    :gerrit_changes,   # e.g. ['84/13084/4', '37/13137/4']
    :stemcell_name,    # e.g. 'bosh-stemcell'
    :stemcell_version, # e.g. '0.6.7'
    :core_ip,          # Static IP for Core CF server (router, cc) e.g. '1.2.3.4'
    :root_dns,         # Root DNS for cc & user apps, e.g. 'mycompanycloud.com'
    :core_server_flavor, # Server size for CF Core; e.g. 'm1.xlarge' on AWS
    :runtimes,         # e.g. { "ruby18" => false, "ruby19" => true }
    :common_password,  # e.g. 'c1oudc0wc1oudc0w` - must be 16 chars for CC password
    :common_persistent_disk, # e.g. 16192 (integer in Mb)
    :admin_emails,     # e.g. ['drnic@starkandwayne.com']
    :dea,              # e.g. { "count" => 2, "flavor" => "m1.large" }
    :security_group,   # e.g. "cloudfoundry-production"
    :available_services, # e.g. ['redis']; restricts supported_services; default - all supported service
    :system_initialized,  # e.g. true / false
  ].each { |attr| create_config_accessor(attr) }

  def microbosh
    unless bosh_target
      raise "please set #bosh_target before requesting microbosh configuration"
    end
    @microbosh ||= Bosh::CloudFoundry::Config::MicroboshConfig.new(bosh_target)
  end

  def self.register_service_config(service_config_class)
    @service_classes ||= []
    @service_classes << service_config_class
  end

  def self.service_classes
    @service_classes
  end

  def service_classes
    self.class.service_classes
  end

  def setup_services
    @services_by_name = {}
    service_classes.each do |service_class|
      service = service_class.build_from_system_config(self)
      service_name = service.service_name
      self.class.create_config_accessor(service_name)
      self.send("#{service_name}=", [])
      @services_by_name[service_name] = service
    end
  end

  def supported_services
    if available_services.is_a?(Array) && available_services.first.is_a?(String)
      available_services
    end
    if available_services
      puts "IGNORING 'available_services' configuration: must be an array of service names"
    end
    @services_by_name.keys
  end

  def services
    @services_by_name.values
  end

  def service(service_name)
    @services_by_name[service_name] ||
      raise("please add #{service_name} support to SystemConfig#service method")
  end

end
