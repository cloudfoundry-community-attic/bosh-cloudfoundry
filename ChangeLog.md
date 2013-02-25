# Change Log

## HEAD

Command "bosh cf prepare system" now (much more quickly) uploads a final release if one doesn't exist. Finally, cf-release includes a final release that works on AWS!

This command can no longer specify what stemcell & release to use; instead edit the manifest directly. The commands can be added back in future if they are useful.

There is now a write up of [the concepts](/docs/concept.md) and constructs being deployed from Anders Sveen!

## v0.5

Gerrit is dead. Long live gerrit. This release is for everyone who is getting started or wants to upgrade. Gerrit is dead.

A few days ago the core Cloud Foundry team shut down the gerrit hosting of cf-release and several patches that we needed to run Cloud Foundry on AWS and/or OpenStack. Fortunately, all the patches have been merged into the staging branch of the cf-release on github. This new release of bosh-cloudfoundry defaults to creating a development (non-final) release of cf-release from its staging branch.

The `bosh cf upload release` command now has a `--branch BRANCH` for uploading a release based on a different branch. It currently defaults to `staging`.

In future, when cf-release eventually merges all the required patches into master branch, we will switch to defaulting to `master`.

And finally, the big requirement for going v1.0, is for all the required patches to be included in a final release of cf-release.

### v0.5.1

Fixes a bug in creating dev releases of cf-release based on branches that aren't "master". It now correctly clones each staging branch into its own repository, built solely off the targeted branch.

## v0.4

Defaults to patched dev release (since a cf-release final release doesn't work).

### v0.4.1

Workaround for cf-release HEAD change - providing `properties.uaa.scim` property now.

## v0.3

Additions:

* OpenStack support! [thx @frodenas; tested by @danhighman] many hugs & kisses to you both!

Fixes:

* changed `health_manager` to `health_manager_next` job (legacy hm was removed in [cf-release patch](https://github.com/cloudfoundry/cf-release/commit/cba60f2e2dee13b7e09eb178eec72aa084a15b1a))
