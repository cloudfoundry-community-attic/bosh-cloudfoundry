# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

module Bosh::CloudFoundry::Providers
  extend self
  # returns a BOSH provider (CPI) specific object
  # with helpers related to that provider
  def for_bosh_provider_name(system_config)
    case system_config.bosh_provider.to_sym
    when :aws
      Bosh::CloudFoundry::Providers::AWS.new(system_config.microbosh.fog_compute)
    when :openstack
      Bosh::CloudFoundry::Providers::OpenStack.new(system_config.microbosh.fog_compute)
    else
      raise "please support #{system_config.bosh_provider} provider"
    end
  end
end

require "bosh-cloudfoundry/providers/aws"
require "bosh-cloudfoundry/providers/openstack"
