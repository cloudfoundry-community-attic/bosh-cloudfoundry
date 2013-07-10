module Bosh::Cloudfoundry
  # This project should support all known versions of Cloud Foundry back to v132.
  # v132 was the first release of Cloud Foundry v2.
  # The project also supports the different CPIs that are supported by bosh.
  # The project also supports different basic sizings/compositions (small dev deployments
  # or large, high-availability production deployments). Each sizing might scale out differently.
  #
  # To achieve these goals it includes templates for each combination of CPI & sizing & release version.
  #
  # This class calculates which deployment template to use for the current deployment.
  class ReleaseVersionedTemplate
    attr_reader :cpi_label
    attr_reader :deployment_size_name

    def initialize(release_version_number, cpi_label, deployment_size_name)
      @release_version_number = release_version_number
      @cpi_label              = cpi_label
      @deployment_size_name   = deployment_size_name
      raise "release_version_number must be an integer" unless release_version_number.is_a?(Fixnum)
    end

    def template_file_path
      File.join(template_base_path, minimum_release_version_number, cpi_label, deployment_size_name, "deployment_file.yml.erb")
    end

    def spec_file_path
      File.join(template_base_path, minimum_release_version_number, cpi_label, deployment_size_name, "spec")
    end

    def spec
      YAML.load_file(spec_file_path)
    end

    # TODO implement a real algorithm when there is a 2nd release & 2nd set of templates
    def minimum_release_version_number
      "v132"
    end

    private
    def template_base_path
      File.expand_path("../../../../templates", __FILE__)
    end
  end
end
