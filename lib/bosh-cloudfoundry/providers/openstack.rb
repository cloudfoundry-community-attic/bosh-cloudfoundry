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

  # @return [Integer] megabytes of RAM for requested flavor of server
  def ram_for_server_flavor(server_flavor)
    if flavor = fog_compute_flavor(server_flavor)
      flavor.ram
    else
      raise "Unknown OpenStack flavor '#{server_flavor}'"
    end
  end

  def fog_compute_flavor(server_flavor)
    compute_flavors.find { |f| f.name == server_flavor }
  end

  def compute_flavors
    fog_compute.flavors
  end

  # Creates or reuses an OpenStack security group and opens ports.
  #
  # +security_group_name+ is the name to be created or reused
  # +ports+ is a hash of name/port for ports to open, for example:
  # {
  #   ssh: 22,
  #   http: 80,
  #   https: 443
  # }
  def create_security_group(security_group_name, ports)
    security_groups = fog_compute.security_groups
    unless sg = security_groups.find { |s| s.name == security_group_name }
      sg = fog_compute.security_groups.create(name: security_group_name, description: security_group_name)
      puts "Created security group #{security_group_name}"
    else
      puts "Reusing security group #{security_group_name}"
    end
    ip_permissions = sg.rules
    ports_opened = 0
    ports.each do |name, port|
      unless port_open?(ip_permissions, port)
        sg.create_security_group_rule(port, port)
        puts " -> opened #{name} port #{port}"
        ports_opened += 1
      end
    end
    puts " -> no additional ports opened" if ports_opened == 0
    true
  end

  def port_open?(ip_permissions, port)
    ip_permissions && ip_permissions.find {|ip| ip["from_port"] <= port && ip["to_port"] >= port }
  end
end
