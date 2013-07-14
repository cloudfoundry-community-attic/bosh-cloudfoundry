module Bosh::Cloudfoundry
  # This project should support all known versions of Cloud Foundry back to v132.
  # v132 was the first release of Cloud Foundry v2.
  # The project also supports the different CPIs that are supported by bosh.
  #
  # This class represents an available release version for a specific CPI.
  # From this class you can navigate to one or more ReleaseVersionCpiSizes (deployment sizes).
  class ReleaseVersionCpi
    attr_reader :release_version
    attr_reader :cpi

    def self.for_cpi(release_version, cpi)
      ReleaseVersionCpi.new(release_version, cpi)
    end

    def initialize(release_version, cpi)
      release_version = ReleaseVersion.for_version(release_version) unless release_version.is_a?(ReleaseVersion)
      raise "CPI #{cpi} not available for version #{release_version.version_number}" unless release_version.valid_cpi?(cpi)
      @release_version, @cpi = release_version, cpi
    end

    def template_dir
      File.join(release_version.template_dir, cpi)
    end

    def spec_path
      File.join(template_dir, "spec")
    end

    def spec
      YAML.load_file(spec_path)
    end

    def available_deployment_sizes
      spec["deployment_sizes"]
    end

    def default_deployment_size
      spec["default_deployment_size"]
    end
  end
end