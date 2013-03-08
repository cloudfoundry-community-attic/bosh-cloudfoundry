# Add new services

The primary purpose of `bosh-cloudfoundry` is to get new ops/admins to deploy Cloud Foundry quickly and successfully on BOSH. But the primary function of the tool is to generate BOSH deployment manifests for the [cf-release](https://github.com/cloudfoundry/cf-release) BOSH release.

As such this tool does not inherently support every aspect of cf-release. Rather we need to implement nice user experience into the CLI (and/or the intermediate system config manfest) for how ops/admins will enable and scale each feature. We then need to determine what to add/change in a deployment manifest for that feature.

For services, we have a simple CLI UI to enable a service:

```
bosh cf add service SERVICE [--flavor m1.small]
bosh deploy
```

This enables the built-in service (where SERVICE might be redis or postgresql) within Cloud Foundry (runs the corresponding service gateway) and deploys a single VM running that service (and the corresponding service node to accompany it).

To scale out a service to add more VMs you run the command again. You can also include a number of VMs to deploy for a specific VM flavor:

```
bosh cf add service SERVICE COUNT [--flavor m1.small]
bosh deploy
```

## Current implemented services

The cf-release currently includes the following built-in services:

* postgresql
* redis

### The goal of 
