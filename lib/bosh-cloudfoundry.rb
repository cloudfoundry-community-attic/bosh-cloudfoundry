require "bosh-cloudfoundry/version"

module Bosh; module CloudFoundry; end; end

require "logger"
require "common/common"
require "common/thread_formatter"
require "cli"

# for generating password
require 'openssl'

# for the #sh helper
require "rake"
require "rake/file_utils"

# for validating DNS -> IP setups
require 'net/dns'

# for:
# * validating compute flavors
# * provisioning IP addresses
require "fog"
require 'fog/aws/models/compute/flavors'

# CLI mixins
require "bosh-cloudfoundry/config_options"
require "bosh-cloudfoundry/bosh_release_manager"
require "bosh-cloudfoundry/gerrit_patches_helper"

require "bosh-cloudfoundry/config"
require "bosh-cloudfoundry/providers"

require "bosh-cloudfoundry/system_deployment_manifest_renderer"
