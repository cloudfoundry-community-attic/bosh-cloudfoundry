module Bosh::Cli::Command
  # Upload a specific bosh release (or the latest one) and upload
  # the latest base stemcell, if target bosh does not already
  # have a stemcell uploaded.
  class PrepareBoshForCloudFoundry < Base
    include Bosh::Cli::Validation

    usage "prepare cf"
    desc "upload latest Cloud Foundry release to bosh"
    option "--release-version version", "Upload a specific older version"
    def prepare_cf
      auth_required
      bosh_status

      release_version = options[:release_version] || latest_release_version

      # Support:
      # * --release-version v132
      # * --release-version 132
      if release_version.to_s =~ /(\d+)/
        release_version = $1
      end
      release_yml = Dir[File.join(bosh_release_dir, "releases", "*-#{release_version}.yml")].first

      release_name = YAML.load_file(release_yml)["name"]

      release_exists = nil
      step("Checking bosh already has release #{release_name} #{release_version}",
            "Currently bosh does not have #{release_name} #{release_version}, uploading...", :non_fatal) do
        release_exists = director.list_releases.find do |existing_release|
          existing_release["name"] == release_name && existing_release["version"].to_s == release_version.to_s
        end
      end
      unless errors.empty?
        say errors.shift.make_yellow
        release_cmd(non_interactive: true).upload(release_yml)
      end

      stemcell_exists = nil
      step("Checking bosh already has base stemcell",
            "Currently bosh does not have base stemcell, uploading...", :non_fatal) do
        stemcell_exists = director.list_stemcells.find do |existing_stemcell|
          existing_stemcell["name"] == stemcell_name
        end
      end
      unless errors.empty?
        say errors.shift.make_yellow
        stemcell_url = "http://bosh-jenkins-artifacts.s3.amazonaws.com/bosh-stemcell/#{bosh_cpi}/latest-bosh-stemcell-#{bosh_cpi}.tgz"
        stemcell_cmd(non_interactive: true).upload(stemcell_url)
      end
    end

    protected
    def stemcell_name
      "bosh-stemcell"
    end

    def bosh_release_dir
      File.expand_path("../../../../../bosh_release", __FILE__)
    end

    def latest_release_version
      # the releases/index.yml contains all the available release versions in an unordered
      # hash of hashes in YAML format:
      #     --- 
      #     builds: 
      #       af61f03c5ad6327e0795402f1c458f2fc6f21201: 
      #         version: 3
      #       39c029d0af9effc6913f3333434b894ff6433638: 
      #         version: 1
      #       5f5d0a7fb577fec3c09408c94f7abbe2d52a042c: 
      #         version: 4
      #       f044d47e0183f084db9dac5a6ef00d7bd21c8451: 
      #         version: 2
      release_index = YAML.load_file(File.join(bosh_release_dir, "releases/index.yml"))
      latest_version = release_index["builds"].values.inject(0) do |max_version, release|
        version = release["version"]
        max_version < version ? version : max_version
      end
      latest_version
    end

    def bosh_status
      @bosh_status ||= begin
        step("Fetching bosh information", "Cannot fetch bosh information", :fatal) do
           @bosh_status = director.get_status
        end
        @bosh_status
      end
    end

    # The CPI (aws/openstack/etc) of the target bosh
    def bosh_cpi
      bosh_status["cpi"]
    end

    # Helper to invoke the Release command's actions
    #
    # Usage to invoke #upload action:
    #
    #   release_cmd(non_interactive: true).upload(release_yml)
    def release_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Release.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

    # Helper to invoke the Stemcell command's actions
    #
    # Usage to invoke #upload action:
    #
    #   stemcell_cmd(non_interactive: true).upload(stemcell_url)
    def stemcell_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Stemcell.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end

  end
end