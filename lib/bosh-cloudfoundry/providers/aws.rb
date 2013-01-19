# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Providers; end; end; end

class Bosh::CloudFoundry::Providers::AWS
  attr_reader :fog_compute
  def initialize(fog_compute=nil)
    @fog_compute = fog_compute
  end

  # @returns [Integer] megabytes of RAM for requested flavor of server
  def ram_for_server_flavor(server_flavor_id)
    if flavor = fog_compute_flavor(server_flavor_id)
      flavor[:ram]
    else
      raise "Unknown AWS flavor '#{server_flavor_id}'"
    end
  end

  # @returns [Hash] e.g. { :bits => 0, :cores => 2, :disk => 0, 
  #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
  # or nil if +server_flavor_id+ is not a supported flavor ID
  def fog_compute_flavor(server_flavor_id)
    aws_compute_flavors.find { |fl| fl[:id] == server_flavor_id }
  end

  # @return [Array] of [Hash] for each supported compute flavor
  # Example [Hash] { :bits => 0, :cores => 2, :disk => 0, 
  #   :id => 't1.micro', :name => 'Micro Instance', :ram => 613}
  def aws_compute_flavors
    Fog::Compute::AWS::FLAVORS
  end

  # @returns [String] provisions a new public IP address in target region
  # TODO nil if none available
  def provision_public_ip_address
    return unless fog_compute
    address = fog_compute.addresses.create
    address.public_ip
    # TODO catch error and return nil
  end

end
