# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# A set of helper methods to add to a Command class to
# get values from Command +options+ if provided,
# else from +Bosh::CloudFoundry::Config+.
# Some helpers also prompt for values if
# no option/common_config value found.
module Bosh::CloudFoundry::ConfigOptions
  DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_common_config")
  DEFAULT_CF_RELEASE_GIT_REPO = "git://github.com/cloudfoundry/cf-release.git"
  DEFAULT_BOSH_GIT_REPO = "git://github.com/cloudfoundry/bosh.git"
  DEFAULT_BASE_SYSTEM_PATH = "/var/vcap/store/systems"
  DEFAULT_RELEASES_PATH = "/var/vcap/store/releases"
  DEFAULT_STEMCELLS_PATH = "/var/vcap/store/stemcells"
  DEFAULT_REPOS_PATH = "/var/vcap/store/repos"
  DEFAULT_CF_RELEASE_NAME = "appcloud" # name of cf-release final release name

  # @return [Bosh::CloudFoundry::CommonConfig] Current common CF configuration
  def common_config
    @common_config ||= begin
      config_file = options[:common_config] || DEFAULT_CONFIG_PATH
      common_config = Bosh::CloudFoundry::CommonConfig.new(config_file)
      common_config.cf_release_git_repo ||= DEFAULT_CF_RELEASE_GIT_REPO
      common_config.bosh_git_repo ||= DEFAULT_BOSH_GIT_REPO
      common_config.save
      common_config
    end
  end

  # @return [Bosh::CloudFoundry::SystemConfig] System-specific configuration
  def system_config
    unless system
      puts caller
      err("Internal bug: cannot access system_config until a system has been selected by user")
    end
    @system_config ||= begin
      system_config = Bosh::CloudFoundry::SystemConfig.new(system)
      system_config.bosh_provider = 'aws' # TODO support other BOSH providers
      system_config.release_name ||= DEFAULT_CF_RELEASE_NAME
      system_config.save
      system_config
    end
  end

  # @return [String] BOSH target to manage CloudFoundry
  def bosh_target
    options[:bosh_target] || config.target
  end

  # @return [String] BOSH target director UUID
  def bosh_target_uuid
    options[:bosh_target_uuid] || config.target_uuid
  end

  # @return [String] CloudFoundry system path
  def system
    options[:system] || common_config.target_system
  end

  # @return [String] CloudFoundry system name
  def system_name
    @system_name ||= system_config.system_name
  end

  # @return [String] Name of BOSH release in target BOSH
  def cf_release_name
    options[:cf_release_name] || system_config.release_name
  end

  # @return [String] Version of BOSH stemcell to use for deployments
  def cf_stemcell_version
    options[:cf_stemcell_version] || system_config.stemcell_version
  end

  # @return [String] public IP address for the Core CF server (to the router)
  def core_ip
    options[:core_ip] || system_config.core_ip || choose_core_ip
  end

  # @return [String] public DNS all apps & api access, e.g. mycompany.com
  def root_dns
    options[:root_dns] || system_config.root_dns || choose_root_dns
  end

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

  def bosh_git_repo
    options[:bosh_git_repo] || common_config.bosh_git_repo
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
    @core_ip = options[:ip] || begin
      err("Currently, please provide static IP via --ip flag")
    end
  end

  # @return [String] Root DNS for applications & CloudController API
  def choose_root_dns
    @root_dns = options[:dns] || begin
      err("Currently, please provide root DNS via --dns flag")
    end
  end

end