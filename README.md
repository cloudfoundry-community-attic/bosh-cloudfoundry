# Run Cloud Foundry on AWS or OpenStack

This is a simple `bosh` CLI plugin to boot up Cloud Foundry and then grow and upgrade and maintain it. Initially runs on AWS or OpenStack via bosh.

Example create/delete scenario:

```
$ bosh prepare cf
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4

...
$ bosh delete cf
```

The deployed Cloud Foundry does not include any data or messaging services for the user applications. These are available as add-ons coming soon.

[![Build Status](https://travis-ci.org/StarkAndWayne/bosh-cloudfoundry.png?branch=v0.7)](https://travis-ci.org/StarkAndWayne/bosh-cloudfoundry)

## Requirements

You will also need an IP address, and a wildcard DNS A record that points to the IP address.

It is also required that you have login access to the same BOSH being used to deploy your Cloud Foundry.

Confirm this by running:

```
$ bosh status
$ bosh deployments
```

The former will confirm you are targeting a BOSH. The latter will display the deployments. One of which should be your Cloud Foundry.

To create your own BOSH on AWS or OpenStack:

```
$ gem install bosh-bootstrap
$ bosh-bootstrap deploy
```

## Installation

Install via RubyGems:

```
$ gem install bosh_cli -v "~> 1.5.0.pre" --source https://s3.amazonaws.com/bosh-jenkins-gems/ 
$ gem install bosh-cloudfoundry -v "~> 0.7.0.alpha"
```

The `bosh_cli` gem is currently only available from S3, rather than RubyGem itself. So it needs to be installed first.

## Usage

Each time you install the latest `bosh-cloudfoundry` gem you may want to re-upload the latest available Cloud Foundry bosh release to your bosh. If no newer release is available then nothing good nor bad will occur.

```
$ bosh prepare cf
Uploading new cf release to bosh...
```

To create/provision a new Cloud Foundry you run the following command. By default, it will select the smallest possible deployment size.

```
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4 --size medium
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4 --size large
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4 --size xlarge
```

By default the core Cloud Foundry server is assigned a 4096 Mb persistent volume/disk. This can be changed later as your Cloud Foundry deployment grows.

NOTE: By default, the `default` security group is used.

You will be prompted to confirm that your chosen/default security group has ports `22`, `80`, `443` and `4222` open. To chose a different security group, use the `--security-group` option:

```
$ bosh create redis --security-group cf-core
```

* TODO - how to show available instance sizes
* TODO - how to update Cloud Foundry servers to a different instance size/flavor
* TODO - how to scale from a small deployment to a large deployment
* TODO - how to update the persistent disks of the deployment

## Initializing Cloud Foundry

Once Cloud Foundry is up and running, follow these steps to login (and discover your password) and create an initial organization and space:

```
$ cf target api.mycloud.com
$ bosh show cf passwords
Common password: 6d7fe84f828b
$ cf login admin
Password> 6d7fe84f828b

$ cf create-org me
$ cf create-space production
$ cf switch-space production
```

## Releasing new plugin gem versions

There are two reasons to release new versions of this plugin.

1. Package the latest [cf-release](https://github.com/cloudfoundry/cf-release) bosh release (which describes how the core Cloud Foundry components are implemented)
2. New features or bug fixes to the plugin

To package the latest "final release" of the Cloud Foundry bosh release into this source repository, run the following command:

```
$ cd /path/to/releases
$ git clone https://github.com/cloudfoundry/cf-release.git
$ cd -
$ rake bosh:release:import[/path/to/releases/cf-release]
# for zsh shell quotes are required around rake arguments:
$ rake bosh:release:import'[/path/to/releases/cf-release]'
```

Note: only the latest "final release" will be packaged.

To locally test the plugin (`bosh` cli loads plugins from its local path automatically):

```
$ cf /path/to/bosh-cloudfoundry
$ bosh cf
```

To release a new version of the plugin as a RubyGem:

1. Edit `bosh-cloudfoundry.gemspec` to update the major or minor or patch version.
2. Run the release command:

```
$ rake release
```

## Contributing

For fixes or features to the `bosh_cli_plugin_redis` (`bosh redis`) plugin:

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
