# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# A set of helper methods to add to a Command class to
# get values from Command +options+ if provided,
# else from +Bosh::CloudFoundry::Config+.
# Some helpers also prompt for values if
# no option/common_config value found.
#
# Assumes there is a +director+ method for making 
# API calls to the target BOSH Director API.
module Bosh::CloudFoundry::ConfigOptions
  DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_common_config")
  DEFAULT_CF_RELEASE_GIT_REPO = "git://github.com/cloudfoundry/cf-release.git"
  DEFAULT_BOSH_GIT_REPO = "git://github.com/cloudfoundry/bosh.git"
  DEFAULT_BASE_SYSTEM_PATH = "/var/vcap/store/systems"
  DEFAULT_RELEASES_PATH = "/var/vcap/store/releases"
  DEFAULT_STEMCELLS_PATH = "/var/vcap/store/stemcells"
  DEFAULT_REPOS_PATH = "/var/vcap/store/repos"
  DEFAULT_RELEASE_NAME = "appcloud" # name of cf-release final release name
  DEFAULT_RELEASE_VERSION = "latest"
  DEFAULT_STEMCELL_NAME = "bosh-stemcell"
  DEFAULT_COMMONT_PERSISTENT_DISK = 16192
  COMMON_PASSWORD_SIZE = 16 # characters; the min for the CC password

  # @return [Bosh::CloudFoundry::Config:: CommonConfig] Current common CF configuration
  def common_config
    @common_config ||= begin
      config_file = options[:common_config] || DEFAULT_CONFIG_PATH
      common_config = Bosh::CloudFoundry::Config:: CommonConfig.new(config_file)
      common_config.cf_release_git_repo ||= DEFAULT_CF_RELEASE_GIT_REPO
      common_config.bosh_git_repo ||= DEFAULT_BOSH_GIT_REPO
      common_config.save
      common_config
    end
  end

  # @return [Bosh::CloudFoundry::Config::SystemConfig] System-specific configuration
  def system_config
    unless system
      puts caller
      err("Internal bug: cannot access system_config until a system has been selected by user")
    end
    @system_config ||= begin
      system_config = Bosh::CloudFoundry::Config::SystemConfig.new(system)
      system_config.bosh_target = options[:bosh_target] || config.target
      system_config.bosh_target_uuid = options[:bosh_target_uuid] || config.target_uuid
      system_config.bosh_provider = 'aws' # TODO support other BOSH providers
      system_config.release_name ||= DEFAULT_RELEASE_NAME
      system_config.release_version ||= DEFAULT_RELEASE_VERSION
      system_config.stemcell_name ||= DEFAULT_STEMCELL_NAME
      system_config.common_persistent_disk = DEFAULT_COMMONT_PERSISTENT_DISK
      system_config.save
      system_config
    end
  end

  # @return [String] CloudFoundry system path
  def system
    options[:system] || common_config.target_system
  end

  # @return [String] CloudFoundry system name
  def system_name
    @system_name ||= system_config.system_name
  end

  # Example usage:
  #   overriddable_config_option :release_name, :system_config, :release_name
  #   overriddable_config_option :core_ip, :system_config
  #   overriddable_config_option :cf_release_git_repo, :common_config
  #
  # +target_config+ is a method name resolving to
  # an instance of either +SystemConfig+ or +CommonConfig+.
  def self.overriddable_config_option(config_option, target_config_accessor, target_config_name=nil)
    target_config_name ||= config_option
    config_option          = config_option.to_sym
    target_config_accessor = target_config_accessor.to_sym
    target_config_name     = target_config_name.to_sym
    # The call:
    #   overriddable_config_option :release_name, :system_config, :release_name
    # Creates the following method:
    #   def release_name
    #     if override = options[:release_name]
    #       system_config.release_name = override
    #       system_config.save
    #     end
    #     return system_config.release_name if system_config.release_name
    #     choose_release_name # if it exists; OR
    #     generate_release_name # if it exists; OR
    #     nil
    #   end
    define_method config_option do
      # convert :system_config into the instance of SystemConfig
      target_config = self.send(target_config_accessor)
      # determine if options has an override for
      if override = options[config_option]
        target_config.send(:"#{target_config_name}=", override)
        target_config.save
      end
      config_value = target_config.send(target_config_name)
      return config_value if config_value
      if self.respond_to?(:"choose_#{config_option}")
        self.send(:"choose_#{config_option}")
      elsif self.respond_to?(:"generate_#{config_option}")
        override = self.send(:"generate_#{config_option}")
        target_config.send(:"#{target_config_name}=", override)
        target_config.save
        override
      else
        nil
      end
    end
  end

  # @return [String] BOSH target to manage CloudFoundry
  overriddable_config_option :bosh_target, :system_config

  # @return [String] BOSH target director UUID
  overriddable_config_option :bosh_target_uuid, :system_config

  # @return [String] Name of BOSH release in target BOSH
  overriddable_config_option :release_name, :system_config

  # @return [String] Version of BOSH release in target BOSH [defaulted above]
  overriddable_config_option :release_version, :system_config

  # @return [String] Name of BOSH stemcell to use for deployments
  overriddable_config_option :stemcell_name, :system_config

  # @return [String] Version of BOSH stemcell to use for deployments
  overriddable_config_option :stemcell_version, :system_config

  # @return [String] public IP address for the Core CF server (to the router)
  overriddable_config_option :core_ip, :system_config

  # @return [String] public DNS all apps & api access, e.g. mycompany.com
  overriddable_config_option :root_dns, :system_config

  # @return [String] flavor of server for the Core server in CloudFoundry deployment
  overriddable_config_option :core_server_flavor, :system_config

  # @return [Array] list of emails for pre-created admin accounts in CloudFoundry deployment
  overriddable_config_option :admin_emails, :system_config

  # @return [Integer] the persistent disk size (Mb) attached to any server that wants one
  overriddable_config_option :common_persistent_disk, :system_config

  # @return [String] a strong password used throughout deployment manifests
  overriddable_config_option :common_password, :system_config

  # @return [String] name of AWS security group being used
  overriddable_config_option :security_group, :system_config

  # @return [String] CloudFoundry BOSH release git URI
  def cf_release_git_repo
    options[:cf_release_git_repo] || common_config.cf_release_git_repo
  end

  # @return [String] Path to store BOSH release projects
  def releases_dir
    options[:releases_dir] || common_config.releases_dir || choose_releases_dir
  end

  # @return [String] Path to cf-release BOSH release
  def cf_release_dir
    options[:cf_release_dir] || common_config.cf_release_dir || begin
      common_config.cf_release_dir = File.join(releases_dir, "cf-release")
      common_config.save
      common_config.cf_release_dir
    end
  end

  # @return [String] Path to store stemcells locally
  def stemcells_dir
    options[:stemcells_dir] || common_config.stemcells_dir || choose_stemcells_dir
  end

  # @return [String] Path to store source repositories locally
  def repos_dir
    options[:repos_dir] || common_config.repos_dir || choose_repos_dir
  end

  # @return [Boolean] true if skipping validations
  def skip_validations?
    options[:no_validation] || options[:no_validations] || options[:skip_validations]
  end

  # @return [Boolean] true if release_version is 'latest'; or no system set yet
  def use_latest_release?
    system.nil? || release_version == "latest"
  end

  def bosh_git_repo
    options[:bosh_git_repo] || common_config.bosh_git_repo
  end

  def deployment_manifest(subsystem="core")
    YAML.load_file(deployment_manifest_path(subsystem))
  end

  def deployment_manifest_path(subsystem="core")
    File.join(system, "deployments", "#{system_name}-#{subsystem}.yml")
  end

  # @return [String] Path to store BOSH systems (collections of deployments)
  def base_systems_dir
    @base_systems_dir ||= options[:base_systems_dir] || common_config.base_systems_dir || begin
      if non_interactive?
        err "Please set base_systems_dir configuration for non-interactive mode"
      end
      
      base_systems_dir = ask("Path for to store all CloudFoundry systems: ") {
        |q| q.default = DEFAULT_BASE_SYSTEM_PATH }
      common_config.base_systems_dir = File.expand_path(base_systems_dir)
      unless File.directory?(common_config.base_systems_dir)
        say "Creating systems path #{common_config.base_systems_dir}"
        FileUtils.mkdir_p(common_config.base_systems_dir)
      end
      common_config.save
      common_config.base_systems_dir
    end
  end

  def choose_releases_dir
    if non_interactive?
      err "Please set releases_dir configuration for non-interactive mode"
    end
    
    releases_dir = ask("Path to store all BOSH releases: ") {
      |q| q.default = DEFAULT_RELEASES_PATH }

    common_config.releases_dir = File.expand_path(releases_dir)
    unless File.directory?(common_config.releases_dir)
      say "Creating releases path #{common_config.releases_dir}"
      FileUtils.mkdir_p(common_config.releases_dir)
    end
    common_config.save
    common_config.releases_dir
  end

  def choose_stemcells_dir
    if non_interactive?
      err "Please set stemcells_dir configuration for non-interactive mode"
    end
    
    stemcells_dir = ask("Path to store downloaded/created stemcells: ") {
      |q| q.default = DEFAULT_STEMCELLS_PATH }

    common_config.stemcells_dir = File.expand_path(stemcells_dir)
    unless File.directory?(common_config.stemcells_dir)
      say "Creating stemcells path #{common_config.stemcells_dir}"
      FileUtils.mkdir_p(common_config.stemcells_dir)
    end
    common_config.save
    common_config.stemcells_dir
  end

  def choose_repos_dir
    if non_interactive?
      err "Please set repos_dir configuration for non-interactive mode"
    end
    
    repos_dir = ask("Path to store source repositories: ") {
      |q| q.default = DEFAULT_REPOS_PATH }

    common_config.repos_dir = File.expand_path(repos_dir)
    unless File.directory?(common_config.repos_dir)
      say "Creating repos path #{common_config.repos_dir}"
      FileUtils.mkdir_p(common_config.repos_dir)
    end
    common_config.save
    common_config.repos_dir
  end

  # @return [String] Primary static IP for CloudController & Router
  def choose_core_ip
    if non_interactive?
      err "Please set core_ip configuration for non-interactive mode"
    end

    if aws?
      system_config.core_ip = ask("Main public IP address (press Enter to provision new IP): ").to_s
    else
      system_config.core_ip = ask("Main public IP address: ").to_s
    end
    if system_config.core_ip.blank?
      say "Provisioning #{bosh_provider} public IP address..."
      system_config.core_ip = provider.provision_public_ip_address
      if system_config.core_ip.blank?
        say "Hmmm, I wasn't able to get a public IP at the moment. Perhaps try again or provision it manually?".red
        exit 1
      end
    end
    system_config.save
    system_config.core_ip
  end

  # @return [String] Root DNS for applications & CloudController API
  def choose_root_dns
    if non_interactive?
      err "Please set root_dns configuration for non-interactive mode"
    end

    system_config.root_dns = ask("Root DNS (e.g. mycompany.com): ").to_s
    system_config.save
    system_config.root_dns
  end

  def choose_core_server_flavor
    if non_interactive?
      err "Please set core_server_flavor configuration for non-interactive mode"
    end

    server_flavor = ask("Server flavor for core of CloudFoundry? ") do |q|
      q.default = default_core_server_flavor
    end
    system_config.core_server_flavor = server_flavor.to_s
    system_config.save
    system_config.core_server_flavor
  end

  def choose_admin_emails
    if non_interactive?
      err "Please set admin_emails configuration for non-interactive mode"
    end

    admin_email_list = ask("Email address for administrator of CloudFoundry? ") do |q|
      git_email = `git config user.email`.strip
      q.default = git_email if git_email.size > 0
    end
    admin_emails = admin_email_list.to_s.split(",")
    system_config.admin_emails = admin_emails
    system_config.save
    system_config.admin_emails
  end

  # generates a password of a specific length; defaults to size +COMMON_PASSWORD_SIZE+
  def generate_common_password(size=COMMON_PASSWORD_SIZE)
    OpenSSL::Random.random_bytes(size).unpack("H*")[0][0..size-1]
  end

  def generate_security_group
    "cloudfoundry-#{system_name}"
  end

  # List of versions of stemcell called "bosh-stemcell" that are available
  # in target BOSH.
  # Ordered by version number.
  # @return [Array] BOSH stemcell versions available in target BOSH, e.g. ["0.6.4", "0.6.7"]
  def bosh_stemcell_versions
    @bosh_stemcell_versions ||= begin
      # [{"name"=>"bosh-stemcell", "version"=>"0.6.7", "cid"=>"ami-9730bffe"}]
      stemcells = director.list_stemcells
      stemcells.select! {|s| s["name"] == stemcell_name}
      stemcells.map { |rel| rel["version"] }.sort { |v1, v2|
        version_cmp(v1, v2)
      }
    end
  end
end