module Bosh::Cloudfoundry
  # This project should support all known versions of Cloud Foundry back to v132.
  # v132 was the first release of Cloud Foundry v2.
  #
  # This class represents an available release version, for which there are a subset of CPIs supported.
  # From this class you can navigate to ReleaseVersionCpi for the CPI specific aspect of a release version;
  # and from ReleaseVersionCpi you can navigate to one or more ReleaseVersionCpiSizes (deployment sizes).
  class ReleaseVersion
    attr_reader :version_number

    def self.for_version(version_number)
      raise "Minimum release version is 132; #{version_number} is too small" if version_number.to_i < 132
      ReleaseVersion.new(available_version(version_number))
    end

    # converts templates/v132, templates/v140, etc into [132, 140]
    def self.available_versions
      @available_versions ||= begin
        Dir[File.join(base_template_dir, "v*")].map {|dir| File.basename(dir)}.map {|version| version[1..-1].to_i}
      end
    end

    def self.available_version(version_number)
      available_version, *versions = available_versions
      while versions && versions.size > 0
        version, *versions = versions
        if version < version_number
          available_version = version
        else
          return available_version
        end
      end
      available_version
    end

    def initialize(version_number)
      @version_number = version_number
    end

    def self.base_template_dir
      File.expand_path("../../../../templates", __FILE__)
    end

    def template_dir
      File.join(self.class.base_template_dir, "v#{version_number}")
    end

    def available_cpi_names
      @available_cpi_names ||= begin
        Dir[File.join(template_dir, "*")].map {|dir| File.basename(dir)}
      end
    end

    def valid_cpi?(cpi)
      available_cpi_names.include?(cpi)
    end
  end
end