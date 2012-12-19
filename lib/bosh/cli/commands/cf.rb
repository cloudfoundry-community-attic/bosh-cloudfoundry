# Copyright (c) 2012-2013 Stark & Wayne, LLC

require 'bosh-cloudfoundry'

module Bosh::Cli::Command
  class CloudFoundry < Base
    include Bosh::Cli::DeploymentHelper

    DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_cf_config")

    def initialize(runner)
      super(runner)
      options[:config] ||= DEFAULT_CONFIG_PATH #hijack Cli::Config
    end

    # @return [Bosh::CloudFoundry::Config] Current CF configuration
    def cf_config
      @config ||= begin
        config_file = options[:config] || Bosh::Cli::DEFAULT_CONFIG_PATH
        Bosh::CloudFoundry::Config.new(config_file)
      end
    end

    # @return [String] CloudFoundry system path
    def system
      options[:system] || cf_config.cf_system
    end

    usage "cf"
    desc  "show cf bosh sub-commands"
    def cf_help
      say("bosh cf sub-commands:")
      nl
      cmds = Bosh::Cli::Config.commands.values.find_all {|c|
        c.usage =~ /^cf/
      }
      Bosh::Cli::Command::Help.list_commands(cmds)
    end

    usage "cf deploy"
    desc  "deploy cloudfoundry"
    def deploy
      p ["deploy", options]
    end

    usage "cf system"
    desc "get/set current system"
    def cf_system(name=nil)
      if name
        set_system(name)
      else
        show_system
      end
    end

    def set_system(name)
      cf_config.cf_system = name
      cf_config.save
    end

    def show_system
      say(system ? "Current CloudFoundry system is '#{system.green}'" : "CloudFoundry system not set")
    end

    usage "cf new system"
    desc  "create a new Cloud Foundry system"
    option "--ip ip", Array, "Static IP for CloudController/router"
    def new_system(name)
      p ["new_system", name, options]
    end
  end
end
