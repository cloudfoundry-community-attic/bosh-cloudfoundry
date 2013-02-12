# Copyright (c) 2012-2013 Stark & Wayne, LLC

require "cli"

module Bosh; module CloudFoundry; module Config; end; end; end

module Bosh::CloudFoundry::Config
  class CommonConfig < Bosh::Cli::Config

    [
      :base_systems_dir, # e.g. /var/vcap/store/systems
      :target_system,        # e.g. /var/vcap/store/systems/production
      :bosh_git_repo,    # e.g. "git://github.com/cloudfoundry/bosh.git"
      :releases_dir,     # e.g. /var/vcap/store/releases
      :stemcells_dir,    # e.g. /var/vcap/store/stemcells
      :repos_dir,        # e.g. /var/vcap/store/repos
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
