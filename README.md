# Run Cloud Foundry on AWS or OpenStack

This is a simple `bosh` CLI plugin to boot up Cloud Foundry and then grow and upgrade and maintain it. Initially runs on AWS or OpenStack via bosh.

Example create/scale/delete scenario:

```
$ bosh prepare cf
$ bosh create cf --public-ip 1.2.3.4
...
$ bosh change cf attributes persistent_disk=8192
...
$ bosh delete cf
```

The deployed Cloud Foundry does not include any data or messaging services for the user applications. These are available as add-ons coming soon.

[![Build Status](https://travis-ci.org/cloudfoundry-community/bosh-cloudfoundry.png?branch=v0.7)](https://travis-ci.org/cloudfoundry-community/bosh-cloudfoundry) [![Stories in Ready](http://badge.waffle.io/cloudfoundry-community/bosh-cloudfoundry.png)](http://waffle.io/cloudfoundry-community/bosh-cloudfoundry)

## What gets created?

The amount of resources used to run Cloud Foundry is determined by the `--deployment-size` you choose (defaults to medium) and the scale you grow it to over time.

Currently there are two deployment sizes supported: medium & large.

For a medium deployment the following VMs are created and have the following vitals after creation:

```
$ bosh create cf ... --deployment-size medium
$ bosh vms --vitals
+-----------+---------+---------------+-------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
| Job/index | State   | Resource Pool | IPs                           |         Load          | CPU  | CPU  | CPU  | Memory Usage   | Swap Usage | System     | Ephemeral  | Persistent |
|           |         |               |                               | (avg01, avg05, avg15) | User | Sys  | Wait |                |            | Disk Usage | Disk Usage | Disk Usage |
+-----------+---------+---------------+-------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
| api/0     | running | small         | 10.159.35.150, 54.225.102.129 | 0.06%, 0.08%, 0.13%   | 0.1% | 0.2% | 0.0% | 13.7% (227.8M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| core/0    | running | small         | 10.118.153.76                 | 1.25%, 0.87%, 0.35%   | 0.0% | 0.0% | 0.1% | 23.6% (391.7M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| data/0    | running | small         | 10.158.26.49                  | 0.02%, 0.02%, 0.07%   | 0.0% | 0.0% | 0.2% | 7.1% (118.9M)  | 0.0% (0B)  | 49%        | 1%         | 4%         |
| dea/0     | running | small         | 10.235.53.185                 | 0.07%, 0.07%, 0.06%   | 0.1% | 0.2% | 0.0% | 19.2% (319.8M) | 0.0% (0B)  | 49%        | 2%         | n/a        |
| uaa/0     | running | small         | 10.29.186.245                 | 0.09%, 0.10%, 0.08%   | 0.1% | 0.0% | 0.1% | 28.3% (469.7M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
+-----------+---------+---------------+-------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
```

For a large deployment, all jobs (moving parts) of Cloud Foundry are isolated into their own VMs, and it includes a syslog aggregator:

```
$ bosh create cf ... --deployment-size large
$ bosh vms --vitals
+---------------------+---------+---------------+------------------------------+-----------------------+------+------+-------+----------------+------------+------------+------------+------------+
| Job/index           | State   | Resource Pool | IPs                          |         Load          | CPU  | CPU  | CPU   | Memory Usage   | Swap Usage | System     | Ephemeral  | Persistent |
|                     |         |               |                              | (avg01, avg05, avg15) | User | Sys  | Wait  |                |            | Disk Usage | Disk Usage | Disk Usage |
+---------------------+---------+---------------+------------------------------+-----------------------+------+------+-------+----------------+------------+------------+------------+------------+
| cloud_controller/0  | running | small         | 10.152.174.25                | 0.15%, 0.12%, 0.08%   | 0.0% | 0.0% | 0.3%  | 11.0% (183.2M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| dea/0               | running | large         | 10.144.83.102                | 0.80%, 0.36%, 0.15%   | 0.0% | 0.0% | 0.0%  | 5.3% (400.5M)  | 0.0% (0B)  | 49%        | 1%         | n/a        |
| health_manager/0    | running | small         | 10.147.214.194               | 0.07%, 0.12%, 0.13%   | 0.0% | 0.0% | 0.2%  | 7.1% (118.4M)  | 0.0% (0B)  | 49%        | 1%         | n/a        |
| login/0             | running | small         | 10.144.157.79                | 0.06%, 0.27%, 0.17%   | 0.0% | 0.0% | 0.2%  | 18.9% (313.8M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| nats/0              | running | small         | 10.152.188.72                | 0.04%, 0.14%, 0.13%   | 0.0% | 0.0% | 0.0%  | 5.9% (98.0M)   | 0.0% (0B)  | 49%        | 1%         | n/a        |
| nfs_server/0        | running | small         | 10.164.22.218                | 0.03%, 0.09%, 0.09%   | 0.0% | 0.0% | 15.5% | 5.2% (87.8M)   | 0.0% (0B)  | 49%        | 1%         | 1%         |
| postgres/0          | running | small         | 10.154.152.54                | 0.25%, 0.17%, 0.12%   | 0.0% | 0.1% | 0.1%  | 6.7% (111.2M)  | 0.0% (0B)  | 49%        | 1%         | 1%         |
| router/0            | running | small         | 10.164.87.23, 54.225.102.129 | 0.04%, 0.09%, 0.07%   | 0.0% | 0.0% | 0.7%  | 5.6% (93.0M)   | 0.0% (0B)  | 49%        | 1%         | n/a        |
| syslog_aggregator/0 | running | small         | 10.165.35.246                | 0.00%, 0.14%, 0.14%   | 0.0% | 0.0% | 0.8%  | 6.3% (105.0M)  | 0.0% (0B)  | 49%        | 1%         | 1%         |
| uaa/0               | running | small         | 10.165.13.230                | 0.11%, 0.59%, 0.38%   | 0.0% | 0.0% | 0.0%  | 29.6% (491.4M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
+---------------------+---------+---------------+------------------------------+-----------------------+------+------+-------+----------------+------------+------------+------------+------------+
```

## Requirements

You will also need an IP address, and a wildcard DNS A record that points to the IP address.

It is also required that you have login access to a BOSH on AWS EC2 or OpenStack (please help with vSphere support).

Confirm this by running:

```
$ bosh status
```

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

### Create initial Cloud Foundry

Each time you install the latest `bosh-cloudfoundry` gem you may want to re-upload the latest available Cloud Foundry bosh release to your bosh. If no newer release is available then nothing good nor bad will occur.

```
$ bosh prepare cf
Uploading new cf release to bosh...
```

To create/provision a new Cloud Foundry you run the following command. By default, it will select the smallest possible deployment size.

```
$ bosh create cf --public-ip 1.2.3.4
$ bosh create cf --public-ip 1.2.3.4 --size medium
$ bosh create cf --public-ip 1.2.3.4 --size large
$ bosh create cf --public-ip 1.2.3.4 --size xlarge
```

It is strongly recommended that you provide your own domain, such as `mycloud.com`. You can purchase and manage your domain through any DNS provider (see below for what needs to be setup), such as [dnsimple.com](https://dnsimple.com/r/af515bc1b6ffc9) (the beloved DNS manager used by Stark & Wayne; as a bonus its an affiliate link so Dr Nic gets free stuff).

To specify a domain:

```
$ bosh create cf --domain mycloud.com --public-ip 1.2.3.4
```

By default, it will configure you to use http://xip.io (a lovely service sponsored by 37signals). You root domain will be `1.2.3.4.xip.io` (where `1.2.3.4` is your IP address).

By default the core Cloud Foundry server is assigned a 4096 Mb persistent volume/disk. This can be changed later as your Cloud Foundry deployment grows.

NOTE: By default, the `default` security group is used.

You will be prompted to confirm that your chosen/default security group has ports `22`, `80`, `443` and `4222` open. To chose a different security group, use the `--security-group` option:

```
$ bosh create cf --security-group cf-core
```

* TODO - how to show available instance sizes
* TODO - how to update Cloud Foundry servers to a different instance size/flavor
* TODO - how to update the persistent disks of the deployment

### Initializing Cloud Foundry

Once Cloud Foundry is up and running, follow these steps to login (and discover your password) and create an initial organization and space:

```
$ cf target api.mycloud.com
$ bosh show cf attributes
...
common_password: 6d7fe84f828b
...
$ cf login admin
Password> 6d7fe84f828b

$ cf create-org me
$ cf create-space production
$ cf switch-space production
```

### Scaling Cloud Foundry

If your persistent disks start filling up (monitor via `bosh vms --vitals`) then you can scale them up by running:

```
$ bosh change cf attributes persistent_disk=8192
```

The initial size of persistent disks is `4096` (4Gb).

## DNS

It is strongly suggested to provide a custom DNS (rather than rely on the free http://xip.io service) as the default DNS for all your applications (including the public API "cloud controller").

You can use the root domain (such as `mycloud.com`) or a subdomain (such as `cf.mycloud.com`).

If you use the [dnsimple.com](https://dnsimple.com/r/af515bc1b6ffc9) service (the beloved DNS manager used by Stark & Wayne; as a bonus it is an affiliate link so Dr Nic gets free stuff) then you will set up your DNS as follows:

<a href="https://dnsimple.com/r/af515bc1b6ffc9"><img src=https://www.evernote.com/shard/s3/sh/a5d22b7e-efef-4c4d-abf6-bac0d343f260/21a09151a6da40e189db349107e6baf0/deep/0/drniccloud.com%20Records%20-%20DNSimple.png /></a>

If you have already deployed Cloud Foundry using the default xip.io DNS service, you can upgrade your Cloud Foundry deployment to use your new custom DNS:

```
$ bosh change cf attributes dns=cf.mycloud.com
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
