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
  class ReleaseVersionCpiSize
    attr_reader :release_version_cpi
    attr_reader :deployment_size

    def initialize(release_version_cpi, deployment_size)
      @release_version_cpi = release_version_cpi
      @deployment_size = deployment_size
    end

    def deployment_attributes_class
      Bosh::Cloudfoundry::DeploymentAttributes
    end

    def template_dir
      File.join(release_version_cpi.template_dir, deployment_size)
    end

    def template_file_path
      File.join(template_dir, "deployment_file.yml.erb")
    end

    def spec_file_path
      File.join(template_dir, "spec")
    end

    def spec
      YAML.load_file(spec_file_path)
    end

    def release_name
      release_version_cpi.release_name
    end

    def release_version_number
      release_version_cpi.release_version_number
    end

  end
end
