# for validating DNS -> IP setups
require 'net/dns'

module Bosh::Cloudfoundry::Validations
  # Validates that +domain+ is an A record that resolves to +expected_ip_addresses+
  # and no other IP addresses.
  #
  # Usage:
  #
  #   dns_mapping = Bosh::Cloudfoundry::Validations::DnsIpMappingValidation.new("foobar.mycloud.com", "1.2.3.4")
  #   if dns_mapping.valid?
  #     puts "`#{dns_mapping.domain}' maps to #{dns_mapping.ip_address}"
  #   else
  #     puts "Validation errors:"
  #     dns_mapping.errors.each do |error|
  #       puts "- %s" % [error]
  #     end
  #     puts "`#{dns_mapping.domain}' does not map to #{dns_mapping.ip_address}"
  #   end
  class DnsIpMappingValidation
    include Bosh::Cli::Validation
    include BoshExtensions

    attr_reader :domain
    attr_reader :ip_address

    def initialize(domain, ip_address)
      @domain = domain
      @ip_address = ip_address
    end

    def perform_validation(options={})
      resolved_a_records = nil
      step("Resolve DNS",
           "Cannot resolve DNS '#{domain}' to an IP address", :fatal) do
         any_resolved_records, resolved_a_records = resolve_dns(domain)
         any_resolved_records
      end

      step("Resolve DNS '#{domain}' to IP '#{ip_address}'",
            "DNS '#{domain}' resolves to: #{resolved_a_records.join(', ')}") do
        resolved_a_records == [ip_address]
      end
    end

    protected
    def resolve_dns(domain)
      domain += "." if domain[-1] != "."
      packet = Net::DNS::Resolver.start(domain, Net::DNS::A)
      resolved_a_records = packet.answer.select { |record|
        record.name == domain
      }.map { |record|
        case record.type
        when "CNAME"
          resolve_dns(record.value)[1]
        when "A"
          record.value
        end
      }.flatten
      [(resolved_a_records.size > 0), resolved_a_records]
    end
  end
end
