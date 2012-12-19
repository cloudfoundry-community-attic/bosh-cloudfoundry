require "bosh-cloudfoundry/version"

module Bosh; module CloudFoundry; end; end

require "logger"
require "common/common"
require "common/thread_formatter"

# for the #sh helper
require "rake"
require "rake/file_utils"

require "bosh-cloudfoundry/config"
