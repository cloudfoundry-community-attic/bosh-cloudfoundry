# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Providers; end; end; end

class Bosh::CloudFoundry::Providers::OpenStack
  attr_reader :fog_compute
  def initialize(fog_compute=nil)
    @fog_compute = fog_compute
  end

  # @return [String] provisions a new public IP address in target region
  # TODO nil if none available
  def provision_public_ip_address
    address = fog_compute.addresses.create
    address.ip
    # TODO catch error and return nil
  end
end
