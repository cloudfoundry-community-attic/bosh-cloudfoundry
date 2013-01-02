# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

class Bosh::CloudFoundry::SystemConfig < Bosh::Cli::Config

  [
    :system_name,      # e.g. production
    :system_dir,       # e.g. /var/vcap/store/systems/production
    :release_name,     # e.g. 'appcloud'
    :stemcell_version, # e.g. '0.6.7'
    :runtimes,         # e.g. { "ruby18" => false, "ruby19" => true }
  ].each do |attr|
    define_method attr do
      read(attr, false)
    end

    define_method "#{attr}=" do |value|
      write_global(attr, value)
    end
  end
end
