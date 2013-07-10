require "yaml"

# for the #sh helper
require "rake"
require "rake/file_utils"

module Bosh::Cli::Command
  class CloudFoundry < Base
    include FileUtils
    include Bosh::Cli::Validation

    usage "cf"
    desc  "show micro cf sub-commands"
    def cf_help
      say("bosh cf sub-commands:")
      nl
      cmds = Bosh::Cli::Config.commands.values.find_all {|c|
        c.usage =~ /cf/
      }
      Bosh::Cli::Command::Help.list_commands(cmds)
    end

    usage "create cf"
    desc "create a deployment file for Cloud Foundry and deploy it"
    option "--size small", "resource size of core server"
    option "--dns mycloud.com", "primary domain"
    option "--ip 1.2.3.4,1.2.3.5", Array, "public IPs; one per router node"
    def create_cf
      ip_addresses = options[:ip]
      err("USAGE: bosh create cf --ip 1.2.3.4 -- please provide one IP address that will be bound to router.") if ip_addresses.blank?
      err("Only one IP address is supported currently. Please create an issue to mention you need more.") if ip_addresses.size > 1

      dns = options[:dns]
      err("USAGE: bosh create cf --dns mycloud.com -- please provide a base DNS that has a '*' A record referencing IPs") unless dns
    end
  end
end