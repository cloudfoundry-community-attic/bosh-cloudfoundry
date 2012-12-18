module Bosh::Cli::Command
  class Cf < Base
    include Bosh::Cli::DeploymentHelper

    usage "cf deploy"
    desc  "deploy cloudfoundry"
    def deploy
      p ["deploy"]
    end

    usage "cf new system NAME"
    desc  "create a new Cloud Foundry system"
    def new_system(name)
      p ["new_system", name]
    end
  end
end
