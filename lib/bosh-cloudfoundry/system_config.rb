# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# Model for the configuration data of a CloudFoundry System
# description.
# Stores the data as a YAML configuration file within a System's
# home folder.
class Bosh::CloudFoundry::SystemConfig < Bosh::Cli::Config

  # Defaults the +system_dir+ and +system_name+ based on the path
  # of the +config_file+.
  # It is assumed that the +config_file+ is located within a folder
  # dedicated to the System begin configured.
  def initialize(system_dir)
    config_file      = File.join(system_dir, "manifest.yml")
    super(config_file, system_dir)
    self.system_dir  = system_dir
    self.system_name = File.basename(system_dir)
  end

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
