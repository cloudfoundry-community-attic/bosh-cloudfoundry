# Bosh::CloudFoundry

Create and manage your Cloud Foundry deployments via the BOSH CLI.

## Usage

You can run the following from your local laptop or a server, such as an `bosh-bootstrap` inception server.

```
gem install bosh-cloudfoundry
bosh cf upload release
bosh cf new system production
bosh cf deploy
```

As the Cloud Foundry BOSH release (`cf-release`) is 1.5 Gb, it may be preferable to manage your Cloud Foundry deployments from your inception server, as created/prepared via `bosh-bootstrap`.

```
$ bosh-bootstrap ssh
# gem install bosh-cloudfoundry
# TMPDIR=/var/vcap/store/tmp bosh cf upload release
# bosh cf new system production
# bosh cf deploy
```

NOTE: `TMPDIR=/var/vcap/store/tmp` tells the upload process to use the larger mounted volume at `/var/vcap/store`. 

### All available commands

```
$ bosh help cf
cf new system <name> [--ip ip] [--dns dns] [--cf-release name] 
    create a new Cloud Foundry system 
    --ip ip           Static IP for CloudController/router, e.g. 1.2.3.4 
    --dns dns         Base DNS for CloudFoundry applications, e.g. vcap.me 
    --cf-release name Name of BOSH release uploaded to target BOSH 

cf system [<name>] 
    get/set current system 

cf upload release [<release_name>] 
    fetch & upload public cloudfoundry release to BOSH 
```

## Development

```
bundle
rake spec
rake install
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
