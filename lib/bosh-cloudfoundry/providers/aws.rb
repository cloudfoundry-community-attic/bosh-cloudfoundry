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

  # Creates or reuses an AWS security group and opens ports.
  # 
  # +security_group_name+ is the name to be created or reused
  # +ports+ is a hash of name/port for ports to open, for example:
  # {
  #   ssh: 22,
  #   http: 80,
  #   https: 443
  # }
  def create_security_group(security_group_name, ports)
    unless fog_compute.security_groups.get(security_group_name)
      sg = fog_compute.security_groups.create(name: security_group_name, description: "microbosh")
      puts "created security group #{security_group_name}"
    else
      puts "reusing security group #{security_group_name}"
    end
    ports.each do |name, port|
      sg.authorize_port_range(port..port)
      puts "opened #{name} port #{port} in security group #{security_group_name}"
    end
  end

end
