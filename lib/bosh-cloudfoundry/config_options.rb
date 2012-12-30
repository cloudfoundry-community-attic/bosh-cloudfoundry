# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# A set of helper methods to add to a Command class to
# get values from Command +options+ if provided,
# else from +Bosh::CloudFoundry::Config+.
# Some helpers also prompt for values if
# no option/cf_config value found.
module Bosh::CloudFoundry::ConfigOptions
  DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_cf_config")
  DEFAULT_CF_RELEASE_GIT_REPO = "git://github.com/cloudfoundry/cf-release.git"
  DEFAULT_BOSH_GIT_REPO = "git://github.com/cloudfoundry/bosh.git"
  DEFAULT_BASE_SYSTEM_PATH = "/var/vcap/store/systems"
  DEFAULT_RELEASES_PATH = "/var/vcap/store/releases"
  DEFAULT_STEMCELLS_PATH = "/var/vcap/store/stemcells"
  DEFAULT_REPOS_PATH = "/var/vcap/store/repos"

  # @return [Bosh::CloudFoundry::Config] Current CF configuration
  def cf_config
    @cf_config ||= begin
      config_file = options[:cf_config] || DEFAULT_CONFIG_PATH
      cf_config = Bosh::CloudFoundry::Config.new(config_file)
      cf_config.cf_release_git_repo ||= DEFAULT_CF_RELEASE_GIT_REPO
      cf_config.bosh_git_repo ||= DEFAULT_BOSH_GIT_REPO
      cf_config.save
      cf_config
    end
  end

  # @return [String] BOSH target to manage CloudFoundry
  def bosh_target
    options[:bosh_target] || config.target
  end

  # @return [String] CloudFoundry system path
  def system
    options[:system] || cf_config.cf_system
  end

  # @return [String] CloudFoundry system name
  def system_name
    @system_name ||= File.basename(File.expand_path(system))
  end

  # @return [String] CloudFoundry BOSH release git URI
  def cf_release_git_repo
    options[:cf_release_git_repo] || cf_config.cf_release_git_repo
  end

  # @return [String] Path to store BOSH release projects
  def releases_dir
    options[:releases_dir] || cf_config.releases_dir || choose_releases_dir
  end

  # @return [String] Path to cf-release BOSH release
  def cf_release_dir
    options[:cf_release_dir] || cf_config.cf_release_dir || begin
      cf_config.cf_release_dir = File.join(releases_dir, "cf-release")
      cf_config.save
      cf_config.cf_release_dir
    end
  end

  # @return [String] Path to store stemcells locally
  def stemcells_dir
    options[:stemcells_dir] || cf_config.stemcells_dir || choose_stemcells_dir
  end

  # @return [String] Path to store source repositories locally
  def repos_dir
    options[:repos_dir] || cf_config.repos_dir || choose_repos_dir
  end

  # @return [Boolean] true if skipping validations
  def skip_validations?
    options[:no_validation] || options[:no_validations] || options[:skip_validations]
  end

  def bosh_git_repo
    options[:bosh_git_repo] || cf_config.bosh_git_repo
  end

  # @return [String] Path to store BOSH systems (collections of deployments)
  def base_systems_dir
    @base_systems_dir ||= options[:base_systems_dir] || cf_config.base_systems_dir || begin
      if non_interactive?
        err "Please set base_systems_dir configuration for non-interactive mode"
      end
      
      base_systems_dir = ask("Path for to store all CloudFoundry systems: ") {
        |q| q.default = DEFAULT_BASE_SYSTEM_PATH }
      cf_config.base_systems_dir = File.expand_path(base_systems_dir)
      unless File.directory?(cf_config.base_systems_dir)
        say "Creating systems path #{cf_config.base_systems_dir}"
        FileUtils.mkdir_p(cf_config.base_systems_dir)
      end
      cf_config.save
      cf_config.base_systems_dir
    end
  end

  def choose_releases_dir
    if non_interactive?
      err "Please set releases_dir configuration for non-interactive mode"
    end
    
    releases_dir = ask("Path to store all BOSH releases: ") {
      |q| q.default = DEFAULT_RELEASES_PATH }

    cf_config.releases_dir = File.expand_path(releases_dir)
    unless File.directory?(cf_config.releases_dir)
      say "Creating releases path #{cf_config.releases_dir}"
      FileUtils.mkdir_p(cf_config.releases_dir)
    end
    cf_config.save
    cf_config.releases_dir
  end

  def choose_stemcells_dir
    if non_interactive?
      err "Please set stemcells_dir configuration for non-interactive mode"
    end
    
    stemcells_dir = ask("Path to store downloaded/created stemcells: ") {
      |q| q.default = DEFAULT_STEMCELLS_PATH }

    cf_config.stemcells_dir = File.expand_path(stemcells_dir)
    unless File.directory?(cf_config.stemcells_dir)
      say "Creating stemcells path #{cf_config.stemcells_dir}"
      FileUtils.mkdir_p(cf_config.stemcells_dir)
    end
    cf_config.save
    cf_config.stemcells_dir
  end

  def choose_repos_dir
    if non_interactive?
      err "Please set repos_dir configuration for non-interactive mode"
    end
    
    repos_dir = ask("Path to store source repositories: ") {
      |q| q.default = DEFAULT_REPOS_PATH }

    cf_config.repos_dir = File.expand_path(repos_dir)
    unless File.directory?(cf_config.repos_dir)
      say "Creating repos path #{cf_config.repos_dir}"
      FileUtils.mkdir_p(cf_config.repos_dir)
    end
    cf_config.save
    cf_config.repos_dir
  end

  # @return [String] Primary static IP for CloudController & Router
  def choose_main_ip
    @main_ip = options[:ip] || begin
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