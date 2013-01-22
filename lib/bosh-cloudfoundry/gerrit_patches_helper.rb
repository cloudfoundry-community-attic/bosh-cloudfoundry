# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; end; end

# There are two concepts of "latest".
# * for upload: "latest" is the highest release in cf-release
# * for manifest creation: "latest" is the highest release already uploaded to the BOSH
module Bosh::CloudFoundry::GerritPatchesHelper

  def extract_refs_change(gerrit_change)
    if gerrit_change =~ %r{(\d+)/(\d+)/(\d+)$}
      "#{$1}/#{$2}/#{$3}"
    else
      nil
    end
  end

  def add_gerrit_refs_change(refs_change)
    system_config.gerrit_changes ||= []
    system_config.gerrit_changes << refs_change
    system_config.save
  end
  
  def apply_gerrit_patches
    # is the gerrit setup necessary; or can use anonymous HTTP?
    # confirm_gerrit_username # http://reviews.cloudfoundry.org/#/settings/
    # confirm_user_added_vcap_ssh_keys_to_gerrit # http://reviews.cloudfoundry.org/#/settings/ssh-keys
    # confirm_ssh_access # ssh -p 29418 drnic@reviews.cloudfoundry.org 2&>1 | grep "Permission denied"
    ssh_uri = "http://reviews.cloudfoundry.org/cf-release"
    chdir(cf_release_dir) do
      create_and_change_into_patches_branch
      system_config.gerrit_changes.each do |refs_change|
        sh "git pull #{ssh_uri} refs/changes/#{refs_change}"
      end
    end
  end

  def create_and_change_into_patches_branch
    sh "git checkout master"
    sh "git branch -D patches 2&>1 /dev/null"
    sh "git checkout -b patches"
  end
end