# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; end

module Bosh::CloudFoundry
  class Config < Bosh::Cli::Config

    [
      :base_systems_dir, # e.g. /var/vcap/store/systems
      :cf_system,        # e.g. /var/vcap/store/systems/production
      :cf_release_name,  # e.g. 'cf-dev' TODO - per system, not global
      :cf_release_git_repo, # e.g. "git@github.com/cloudfoundry/cf-release.git"
      :releases_dir,     # e.g. /var/vcap/store/releases
      :cf_release_dir,   # e.g. /var/vcap/store/releases/cf-release
    ].each do |attr|
      define_method attr do
        read(attr, false)
      end

      define_method "#{attr}=" do |value|
        write_global(attr, value)
      end
    end
  end
end
