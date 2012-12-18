# Bosh::CloudFoundry

Create and manage your Cloud Foundry deployments via the BOSH CLI.

## Usage

You can run the following from your local laptop or a server, such as an `bosh-bootstrap` inception server.

```
gem install bosh-cloudfoundry
bosh cf new system production
bosh cf deploy
```

As the Cloud Foundry BOSH release (`cf-release`) is 1.5 Gb, it may be preferable to manage your Cloud Foundry deployments from your inception server, as created/prepared via `bosh-bootstrap`.

```
$ bosh-bootstrap ssh
# gem install bosh-cloudfoundry
# bosh cf new system production
# bosh cf deploy
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
