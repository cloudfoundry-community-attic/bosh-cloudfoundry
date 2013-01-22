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
  def effective_release_version
    if release_version == "latest"
      latest_final_release_tag_number.to_s
    else
      release_version.to_s
    end
  end

  # for upload, "latest" is the newest release in cf-release
  def upload_final_release
    release_number = use_latest_release? ? 
      latest_final_release_tag_number :
      release_version
    chdir(cf_release_dir) do
      bosh_cmd "upload release releases/appcloud-#{release_number}.yml"
    end
    @bosh_releases = nil # reset cache
  end

  # FIXME why not look in releases/final.yml to get the number?
  # then it would also work for dev_releases?

  # Examines the git tags of the cf-release repo and
  # finds the latest tag for a release (v126 or v119-fixed)
  # and returns the integer value (126 or 119).
  # @return [Integer] the number of the latest final release tag
  def latest_final_release_tag_number
    # FIXME this assumes the most recent tag is a final release:
    #  (v126)
    #  (v126, origin/built)
    #  (v119-fixed)
    # But it might return an empty row
    # Example values in the output from the "git log" command below is:
    # (v126, origin/built)
    # (v125)
    # (origin/te)
    # (v121)
    # (v120)
    # (v119-fixed)
    # (v119)
    # (origin/v113-fix)
    # (v109)
    # 
    # (origin/warden)
    # 
    chdir(cf_release_dir) do
      latest_git_tag = `git log --tags --simplify-by-decoration --pretty='%d' | head -n 1`
      if latest_git_tag =~ /v(\d+)/
        return $1.to_i
      else
        say "The following command did not return a v123 formatted number:".red
        say "git log --tags --simplify-by-decoration --pretty='%d' | head -n 1"
        say "Method #latest_final_release_tag_number needs to be fixed"
        err("Please raise an issue with https://github.com/StarkAndWayne/bosh-cloudfoundry/issues")
      end
    end
  end

  # Looks at the last line of releases/index.yml in cf-release 
  # for the latest release number that could be uploaded
  # @returns [String] a number such as "126"
  def latest_uploadable_final_release_number
    chdir(cf_release_dir) do
      `tail -n 1 releases/index.yml | awk '{print $2}'`.strip
    end
  end

  # Looks at the last line of releases/index.yml in cf-release 
  # for the latest release number that could be uploaded
  # @returns [String] a dev release code such as "126.8-dev"
  def latest_uploadable_dev_release_number
    chdir(cf_release_dir) do
      `tail -n 1 dev_releases/index.yml | awk '{print $2}'`.strip
    end
  end

  # @returns [String] absolute path to latest release to be uploaded
  def latest_dev_release_filename
    dev_release_number = latest_uploadable_dev_release_number
    return nil unless dev_release_number.size > 0
    File.join(cf_release_dir, "#{release_name}-#{dev_release_number}.yml")
  end

  def create_dev_release(release_name="appcloud-dev")
    chdir(cf_release_dir) do
      write_dev_config_file(release_name)
      sh "bosh create release --with-tarball --force"
    end
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

  def upload_dev_release
    chdir(cf_release_dir) do
      sh "bosh -n --color upload release"
    end
    @bosh_releases = nil # reset cache
  end

  # assume unchanged config/final.yml
  def clone_or_update_cf_release
    cf_release_dirname = File.basename(cf_release_dir)
    if File.directory?(cf_release_dir)
      chdir(cf_release_dir) do
        sh "git pull origin master"
      end
    else
      chdir(releases_dir) do
        sh "git clone #{cf_release_git_repo} #{cf_release_dirname}"
        chdir(cf_release_dirname) do
          sh "git update-index --assume-unchanged config/final.yml 2>/dev/null"
        end
      end
    end
    chdir(cf_release_dir) do
      say "Rewriting all git:// & git@ to https:// ..."
      # Snippet written by Mike Reeves <swampfoxmr@gmail.com> on bosh-users mailing list
      # Date 2012-12-06
      sh "sed -i 's#git@github.com:#https://github.com/#g' .gitmodules"
      sh "sed -i 's#git://github.com#https://github.com#g' .gitmodules"
      sh "git submodule update --init"
    end
  end

  def default_release_name
    "appcloud"
  end

  def switch_to_development_release
    system_config.release_name = default_release_name + "-dev"
    system_config.release_version = "latest"
    system_config.save
  end

  def switch_to_final_release
    system_config.release_name = default_release_name
    system_config.release_version = "latest"
    system_config.save
  end
end