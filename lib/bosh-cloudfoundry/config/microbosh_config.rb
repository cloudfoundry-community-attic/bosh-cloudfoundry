# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

# Helper to create a Fog::Connection based on auto-discovery
# of the CPI credentials of a microbosh's local configuration.
#
# If ~/.bosh_deployer_config exists, it contains the location of
# the `micro_bosh.yml` for each microbosh.
class Bosh::CloudFoundry::Config::MicroboshConfig
  attr_reader :deployed_microboshes, :target_bosh_host

  def initialize(target_bosh_host)
    @target_bosh_host = target_bosh_host
  end

  def valid?
    validate_target_bosh_host &&
    validate_bosh_deployer_config
  end

  def fog_compute
    return nil unless valid?
    @fog_compute ||= Fog::Compute.new(fog_connection_properties)
  end

  def fog_connection_properties
    if aws?
      ec2_endpoint = provider_credentials["ec2_endpoint"]
      if ec2_endpoint =~ /ec2\.([\w-]+)\.amazonaws\.com/
        region = $1
      else
        raise "please add support to extra 'region' from #{ec2_endpoint}"
      end
      {
        provider: "aws",
        region: region,
        aws_access_key_id: provider_credentials["access_key_id"],
        aws_secret_access_key: provider_credentials["secret_access_key"]
      }
    else
      raise "please implement #fog_credentials for #{bosh_provider}"
    end
  end

  def bosh_provider
    cloud_config["plugin"]
  end

  def provider_credentials
    cloud_config["properties"][bosh_provider]
  end

  def aws?
    bosh_provider == "aws"
  end

  # micro_bosh.yml looks like:
  #
  # cloud:
  #   plugin: aws
  #   properties:
  #     aws:
  #       access_key_id: ACCESS
  #       secret_access_key: SECRET
  #       ec2_endpoint: ec2.us-east-1.amazonaws.com
  #       default_security_groups:
  #       - microbosh-aws-us-east-1
  #       default_key_name: microbosh-aws-us-east-1
  #       ec2_private_key: /home/vcap/.ssh/microbosh-aws-us-east-1.pem
  def cloud_config
    microbosh_config["cloud"]
  end

  def microbosh_config
    YAML.load_file(target_microbosh_config_path)
  end

  # ensure input value is a valid URI
  def validate_target_bosh_host
    URI.parse(target_bosh_host)
    true
  rescue
    false
  end

  # ensure there is a ~/.bosh_deployer_config
  def validate_bosh_deployer_config
    return false unless File.exist? bosh_deployer_config
    @deployed_microboshes = YAML.load_file(bosh_deployer_config)
    return false unless target_microbosh_config_path
    true
  end

  def bosh_deployer_config
    File.expand_path("~/.bosh_deployer_config")
  end

  # .bosh_deployer_config looks like:
  #
  # deployment: 
  #   http://1.2.3.4:25555: /path/to/micro_bosh.yml
  def target_microbosh_config_path
    deployed_microboshes["deployment"][target_bosh_host]
  end
end