# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# There are two concepts of "latest".
# * for upload: "latest" is the highest release in cf-release
# * for manifest creation: "latest" is the highest release already uploaded to the BOSH
module Bosh::CloudFoundry::BoshReleaseManager
  
  # @return [Array] BOSH releases available in target BOSH
  # [{"name"=>"appcloud", "versions"=>["124", "126"], "in_use"=>[]}]
  def bosh_releases
    @bosh_releases ||= releases = director.list_releases
  end

  # @return [Array] BOSH release names available in target BOSH
  def bosh_release_names
    @bosh_release_names ||= bosh_releases.map { |rel| rel["name"] }
  end

  # @return [Array] BOSH release versions for specific release name in target BOSH
  def bosh_release_versions(release_name)
    if release = bosh_releases.find { |rel| rel["name"] == release_name }
      release["versions"]
    else
      []
    end
  end

  def release_name_version
    "#{release_name}/#{release_version}"
  end

  # @return [Version String] BOSH version number; converts 'latest' into actual version
  # TODO implement this; map "latest" to highest uploaded release in BOSH
  # return "unknown" if BOSH has no releases of this name yet
  def effective_release_version
    release_version.to_s
  end

  # for upload, "latest" is the newest release in cf-release
  def upload_final_release
    release_number = use_latest_release? ? 
      latest_uploadable_final_release_number :
      release_version
    chdir(cf_release_branch_dir) do
      bosh_cmd "upload release releases/appcloud-#{release_number}.yml"
    end
    @bosh_releases = nil # reset cache
  end

  # Looks at the last line of releases/index.yml in cf-release 
  # for the latest release number that could be uploaded
  # @returns [String] a number such as "126"
  def latest_uploadable_final_release_number
    chdir(cf_release_branch_dir) do
      return `tail -n 1 releases/index.yml | awk '{print $2}'`.strip
    end
  end

  # Looks at the last line of releases/index.yml in cf-release 
  # for the latest release number that could be uploaded
  # @returns [String] a dev release code such as "126.8-dev"
  def latest_uploadable_dev_release_number
    chdir(cf_release_branch_dir) do
      return `tail -n 1 dev_releases/index.yml | awk '{print $2}'`.strip
    end
  end

  # @returns [String] absolute path to latest release to be uploaded
  def latest_dev_release_filename
    dev_release_number = latest_uploadable_dev_release_number
    return nil unless dev_release_number.size > 0
    File.join(cf_release_dir, "#{release_name}-#{dev_release_number}.yml")
  end

  def create_and_upload_dev_release
    release_name = default_dev_release_name
    chdir(cf_release_branch_dir) do
      write_dev_config_file(release_name)
      sh "bosh -n --color create release --with-tarball --force"
      sh "bosh -n --color upload release"
    end
    @bosh_releases = nil # reset cache
  end

  def write_dev_config_file(release_name)
    dev_config_file = "config/dev.yml"
    if File.exist?(dev_config_file)
      dev_config = YAML.load_file(dev_config_file)
    else
      dev_config = {}
    end
    dev_config["dev_name"] = release_name
    File.open(dev_config_file, "w") { |file| file << dev_config.to_yaml }
  end

  # clones or updates cf-release for a specific branch
  # For all defaults, clones into:
  # * /var/vcap/store/releases/cf-release/master (cf_release_branch_dir)
  #
  # Uses:
  # * releases_dir (e.g. '/var/vcap/store/releases')
  # * cf_release_branch (e.g. 'staging')
  # * cf_release_branch_dir (e.g. '/var/vcap/store/releases/cf-release/staging')
  def clone_or_update_cf_release
    raise "invoke #set_cf_release_branch(branch) first" unless cf_release_branch_dir
    if File.directory?(cf_release_branch_dir)
      chdir(cf_release_branch_dir) do
        sh "git pull origin #{cf_release_branch}" # recursive is below
      end
    else
      chdir(releases_dir) do
        sh "git clone -b #{cf_release_branch} #{cf_release_git_repo} #{cf_release_branch_dir}"
        chdir(cf_release_branch_dir) do
          sh "git update-index --assume-unchanged config/final.yml 2>/dev/null"
        end
      end
    end
  end

  # when creating a dev release, need to pull down submodules
  def prepare_cf_release_for_dev_release
    chdir(cf_release_branch_dir) do
      say "Rewriting all git:// & git@ to https:// ..."
      # Snippet written by Mike Reeves <swampfoxmr@gmail.com> on bosh-users mailing list
      # Date 2012-12-06
      sh "sed -i 's#git@github.com:#https://github.com/#g' .gitmodules"
      sh "sed -i 's#git://github.com#https://github.com#g' .gitmodules"
      sh "git submodule update --init --recursive"
    end
  end

  def default_release_name
    "appcloud"
  end

  def default_dev_release_name(branch_name=cf_release_branch)
    suffix = "-#{branch_name || 'dev'}"
    default_release_name + suffix
  end

  def switch_to_development_release
    system_config.release_name = default_dev_release_name(cf_release_branch)
    system_config.release_version = "latest"
    system_config.release_type = "final"
    system_config.save
  end

  def switch_to_final_release
    system_config.release_name = default_release_name
    system_config.release_version = "latest"
    system_config.release_type = "dev"
    system_config.save
  end
end
