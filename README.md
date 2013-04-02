# Bosh::CloudFoundry

You want Cloud Foundry? You can now create, scale, upgrade and patch one or more Cloud Foundry deployments using very simple, easy to learn and remember CLI commands.

Currently supports AWS and OpenStack only. vSphere and vCloud support will require someone to tell me that they really want it.

[![Build Status](https://travis-ci.org/StarkAndWayne/bosh-cloudfoundry.png?branch=master)](https://travis-ci.org/StarkAndWayne/bosh-cloudfoundry) [![Code Climate](https://codeclimate.com/github/StarkAndWayne/bosh-cloudfoundry.png)](https://codeclimate.com/github/StarkAndWayne/bosh-cloudfoundry)

## Zero to Cloud Foundry in a few hours

If you have an AWS or OpenStack account then you can deploy a running Cloud Foundry VM by following this very simple tutorial. It first uses the very powerful [bosh-bootstrap](https://github.com/StarkAndWayne/bosh-bootstrap) tool to deploy a BOSH, and then using this project (a plugin for the BOSH CLI) it will do everything necessary to deploy Cloud Foundry via your shiny new, empty BOSH.

**You should not need to know anything before running this tutorial.** If you do this tutorial and you feel it was too complex or you needed to know something additional, please [create a ticket](https://github.com/StarkAndWayne/bosh-cloudfoundry/issues).

## Run these steps on your local laptop/desktop

```
gem install bosh-bootstrap
bosh-bootstrap deploy
# prompts for AWS/OpenStack credentials
# and some other fields that you can
# just press Enter for.
```
## SSH into inception VM and run these commands on that inception VM 
### (also see 'tmux' and 'mosh' commands)
```
bosh-bootstrap ssh

bosh cf prepare system production
# prompts for a DNS host for your CloudFoundry, such as mycompany.com
# will generate a new IP address
# now setup your DNS for *.mycompany.com => new IP address
# the re-run:
bosh cf prepare system production

# use special "cf deploy" to install VMC & create initial VMC user
bosh cf deploy

# now we can grow our single VM deployment

bosh cf change deas 1
bosh cf add service postgresql
bosh deploy
```

Overtime, as you add more DEAs and other service nodes, your set of VMs might look like:

```
$ bosh vms
+-----------------------------+---------+---------------------------+-----------------------------+
| Job/index                   | State   | Resource Pool             | IPs                         |
+-----------------------------+---------+---------------------------+-----------------------------+
| core/0                      | running | core                      | 10.4.70.116, 54.235.200.165 |
| dea/0                       | running | dea                       | 10.4.49.7                   |
| dea/1                       | running | dea                       | 10.111.39.12                |
| postgresql_m1_medium_free/0 | running | postgresql_m1_medium_free | 10.4.71.164                 |
| postgresql_m1_small_free/0  | running | postgresql_m1_small_free  | 10.110.83.128               |
| postgresql_m1_small_free/1  | running | postgresql_m1_small_free  | 10.189.103.26               |
+-----------------------------+---------+---------------------------+-----------------------------+
```

## Requirements

* Ruby 1.9
* BOSH running on AWS (other CPIs coming)
* Unix-based local system (Windows support for bosh-bootstrap is a priority)

## Usage

The tool is very simple to use and to get CloudFoundry deployed on a small set of initial servers.

```
gem install bosh-cloudfoundry
bosh cf prepare system demo
bosh cf deploy
```

The above can be run the following from your local laptop or a server, such as an `bosh-bootstrap` inception server. 

The latter is preferred. As the Cloud Foundry BOSH release (`cf-release`) is 1.5 Gb, it may be preferable to manage your Cloud Foundry deployments from your inception server, as created/prepared via `bosh-bootstrap`.

```
bosh-bootstrap deploy --latest-stemcell
bosh-bootstrap ssh

# now on the inception VM
gem install bosh-cloudfoundry
export TMPDIR=/var/vcap/store/tmp
bosh cf prepare system production
# prompts for a DNS host for your CloudFoundry, such as mycompany.com
bosh cf change deas 1
bosh cf add service postgresql 1
bosh cf deploy
```

During `bosh cf prepare system production`, it will automatically upload the latest release of CloudFoundry (the latest final [BOSH release](http://github.com/cloudfoundry/cf-release)) and the latest stable stemcell (becomes the base AMI for AWS, for example).

NOTE: `export TMPDIR=/var/vcap/store/tmp` tells the upload process to use the larger mounted volume at `/var/vcap/store`. 

You can upload a more recent stemcell or create a new one from source, respectively:

```
bosh cf upload stemcell --latest
bosh cf upload stemcell --custom
```

You can upload a more recent final BOSH release of CloudFoundry, or create a non-final version from the very latest commits to the CloudFoundry BOSH release, respectively:

```
bosh cf upload release
bosh cf upload release --dev
```

### All available commands

Prefix each with `bosh`:

```
cf prepare system [<name>] [--core-ip ip] [--root-dns dns] 
                  [--core-server-flavor flavor] [--release-name name] [--release-version 
                  version] [--stemcell-name name] [--stemcell-version version] 
                  [--admin-emails email1,email2] [--skip-validations] 
    create CloudFoundry system 
    --core-ip ip                 Static IP for CloudController/router, e.g. 1.2.3.4 
    --root-dns dns               Base DNS for CloudFoundry applications, e.g. vcap.me 
    --core-server-flavor flavor  Flavor of the CloudFoundry Core server. Default: 'm1.large' 
    --release-name name          Name of BOSH release within target BOSH. Default: 'appcloud' 
    --release-version version    Version of target BOSH release within target BOSH. Default: 'latest' 
    --stemcell-name name         Name of BOSH stemcell within target BOSH. Default: 'bosh-stemcell' 
    --stemcell-version version   Version of BOSH stemcell within target BOSH. Default: determines latest for stemcell 
    --admin-emails email1,email2 Admin email accounts in created CloudFoundry 
    --skip-validations           Skip all validations 

cf change deas [<server_count>] [--flavor flavor] 
    change the number/flavor of DEA servers (servers that run CF apps) 
    --flavor flavor Change flavor of all DEA servers 

cf add service <service_name> [<additional_count>] [--flavor flavor] 
    add additional CloudFoundry service node 
    --flavor flavor Server flavor for additional service nodes 

cf upload stemcell [--latest] [--custom] 
    download/create stemcell & upload to BOSH 
    --latest Use latest stemcell; possibly not tagged stable 
    --custom Create custom stemcell from BOSH git source 

cf upload release [--dev] 
    fetch & upload public cloudfoundry release to BOSH 
    --dev Create development release from very latest cf-release commits 

cf deploy 
    deploy CloudFoundry system or apply any changes 

cf watch nats 
    subscribe to all nats messages within CloudFoundry
```

## Services

By default your CloudFoundry deployment comes with no built-in services. Instead, you easily enable each one and allocate it resources using the `bosh cf add service NAME` command; then deploy again.

```
$ bosh cf add service postgresql
$ bosh cf add service redis
$ bosh deploy
```

Eventually the new service node servers will be up and running, and then the VMC client will be able to create/bind/delete these services with your CloudFoundry applications.

For example:

``` 
============== System Services ==============
 
+------------+---------+---------------------------------------+
| Service    | Version | Description                           |
+------------+---------+---------------------------------------+
| postgresql | 9.0     | PostgreSQL database service (vFabric) |
| redis      | 2.2     | Redis key-value store service         |
+------------+---------+---------------------------------------+
 
=========== Provisioned Services ============
 
+------------------+------------+
| Name             | Service    |
+------------------+------------+
| postgresql-6d01e | postgresql |
| postgresql-ff0c1 | postgresql |
| redis-d0d3d      | redis      |
+------------------+------------+g
```

## Orders of easiness vs powerfulness

```

+--------------+     +-----------------+       +---------------------+
|              |     |                 |       |                     |
|  CLI         |     |                 |       |                     |
|  commands    +---->|                 |       |                     |
|              |     |  system         |       |  deployment         |
|              |     |  config         |       |  manifest           |
+--------------+     |  (yaml)         |       |  (yaml)             |
                     |                 +------>|                     |
                     |                 |       |                     |
                     |                 |       |                     |
                     |                 |       |                     |
                     |                 |       |                     |
                     +-----------------+       |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               |                     |
                                               +---------------------+
```

## Development

```
bundle
bundle exec rake spec
bundle exec rake install
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/StarkAndWayne/bosh-cloudfoundry/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

