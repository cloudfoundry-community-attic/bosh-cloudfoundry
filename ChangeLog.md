# Change Log

## v0.7 - now supporting Cloud Foundry v2!

`bosh-cloudfoundry` is back, rewritten, and supporting Cloud Foundry v2.

```
$ gem install bosh-cloudfoundry -v "~> 0.7.0.alpha"
$ bosh prepare cf
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4
```

As a rewrite, v0.7 initially implements fewer features than were in v0.6. It takes advantage of the long-awaited first final release of [cf-release](https://github.com/cloudfoundry/cf-release) for Cloud Foundry v2 (v132).

The rewrite introduces some new implementation/feature concepts:

* using `bosh diff` (aka biff) to generate the deployment file
* bundles all final releases into the project & distributed rubygem/plugin (no runtime dependency on cf-release git repository; only the public blobstore)
* templates are versioned for each final release (unless new templates not required for new release)
* different sizes of deployments (orders of magnitude), such as small, medium & large: `bosh create cf --deployment-size large`
* mutable/changable properties (and immutable properties) for each template version: `bosh change cf attributes persistent_disk=8192`

The latter means that new versions of this rubygem can be published that are backwards compatible with aging deployments of Cloud Foundry. There should not be any forced coupling of old `bosh-cloudfoundry` to old `cf-release` final releases.
