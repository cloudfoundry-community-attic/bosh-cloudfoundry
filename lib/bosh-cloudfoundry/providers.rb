# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

module Bosh::CloudFoundry::Providers
  extend self
  # returns a BOSH provider (CPI) specific object
  # with helpers related to that provider
  def for_bosh_provider_name(bosh_provider_name)
    case bosh_provider_name.to_sym
    when :aws
      Bosh::CloudFoundry::Providers::AWS.new
    else
      raise "please support #{bosh_provider_name} provider"
    end
  end
end

require "bosh-cloudfoundry/providers/aws"
