# Change Log

## v0.8

* Cloud Foundry v169, assumes BOSH 1.2200.0+
* Now includes loggregator, hm9000 and haproxy
* [medium] Various Cloud Controller job templates running on different VMs due to each one demanding it perform NFS mounting
* [large] Now 15 VMs instead of 9 due to additional jobs - cc worker & clock, etcd, hm9000 and haproxy.

Note: only one CC worker process is running due to conflict with NFS mounting. To be resolved.

## v0.7 - now supporting Cloud Foundry v2!

`bosh-cloudfoundry` is back, rewritten, and supporting Cloud Foundry v2.

```
$ gem install bosh-cloudfoundry
$ bosh prepare cf
$ bosh create cf --dns mycloud.com --public-ip 1.2.3.4
```

The rewrite introduces some new implementation/feature concepts:

* takes advantage of the long-awaited first final release of [cf-release](https://github.com/cloudfoundry/cf-release) for Cloud Foundry v2 (v132).
* bundles all final releases into the project & distributed rubygem/plugin (no runtime dependency on cf-release git repository; only the public blobstore)
* using `bosh diff` (aka biff) to generate the deployment file
* templates are versioned for each final release (unless new templates not required for new release)
* different sizes of deployments (orders of magnitude), such as small, medium & large: `bosh create cf --deployment-size large`
* mutable/changable properties (and immutable properties) for each template version: `bosh change cf attributes persistent_disk=8192`
* can initially use public http://xip.io for DNS and change to custom DNS later: `bosh change cf attributes dns=cf.mycloud.com`
* v141 cf release & template fixes [v0.7.1]
* bosh stemcells now have cpi/hypervisor in name [v0.7.2]
* cc.external_host is assumed to be 'api' [v0.7.3]
* v146 cf release [v0.7.4]
* v146 fix - do not explicitly specify (wrong) NFS path [v0.7.5; thx Troy Astle]
* v149 added, includes required nats.machines property [v0.7.6]

The latter means that new versions of this rubygem can be published that are backwards compatible with aging deployments of Cloud Foundry. There should not be any forced coupling of old `bosh-cloudfoundry` to old `cf-release` final releases.
