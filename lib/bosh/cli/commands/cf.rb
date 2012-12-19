# Copyright (c) 2012-2013 Stark & Wayne, LLC

require 'bosh-cloudfoundry'

module Bosh::Cli::Command
  class CloudFoundry < Base
    include Bosh::Cli::DeploymentHelper

    DEFAULT_CONFIG_PATH = File.expand_path("~/.bosh_cf_config")

    def initialize(runner)
      super(runner)
      options[:config] ||= DEFAULT_CONFIG_PATH # Hijack Cli::Config
    end

    usage "cf deploy"
    desc  "deploy cloudfoundry"
    def deploy
      p ["deploy", options]
    end

    usage "cf system"
    desc "get/set current system"
    def set_system(name=nil)
      p ["system", name, options]
    end

    usage "cf new system"
    desc  "create a new Cloud Foundry system"
    option "--ip ip", Array, "Static IP for CloudController/router"
    def new_system(name)
      p ["new_system", name, options]
    end
  end
end
