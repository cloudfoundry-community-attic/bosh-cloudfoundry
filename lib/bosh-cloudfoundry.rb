require "bosh-cloudfoundry/version"

module Bosh; module CloudFoundry; end; end

require "logger"
require "common/common"
require "common/thread_formatter"
require "cli"

# for the #sh helper
require "rake"
require "rake/file_utils"

# for validating DNS -> IP setups
require 'net/dns'

require "bosh-cloudfoundry/config"
