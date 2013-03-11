# Add new built-in services

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

## Implement a service

### What does 'implementing a service' mean?

It means we:

* support CLI for adding/scaling services, which stores requirements in the SystemConfig intermediate manifest
* convert the SystemConfig intermediate manifest into the correct deployment manifest

In the sections below, let's consider we're implementing the `mysql` service (which is already implemented in cf-release).

### Start with example deployment manifests

The example deployment manifests for services (and other tricks that we can do) are in the [spec/assets/deployments](https://github.com/StarkAndWayne/bosh-cloudfoundry/tree/master/spec/assets/deployments) folder.

When adding a new service, start by adding new examples to this folder.

### Write specs to render your examples

Add specs to [system_deployment_manifest_renderer_spec.rb](https://github.com/StarkAndWayne/bosh-cloudfoundry/blob/master/spec/unit/system_deployment_manifest_renderer_spec.rb) that expect to render your example spec(s) based on specific SystemConfig

Look at the redis and postgresql specs for examples.

In a terminal window, you can run `guard` to continuously run your failing specs until they start passing:

```
$ guard
```

### Extend SystemConfig

In your manifest spec, you might want to include an extension to `@system_config` so you can implement the following idea:

``` ruby
@system_config.mysql = [
  { "count" => 1, "flavor" => "m1.small", "plan" =>"free" },
]
```

Initially, the [SystemConfig](https://github.com/StarkAndWayne/bosh-cloudfoundry/blob/master/lib/bosh-cloudfoundry/config/system_config.rb) class (`@system_config`) does not have a `#mysql=` method. Let's now implement support for the new service.

### Creating a service config class

For each of postgresql and redis there is a class that knows about its service's configuration, [PostgresqlServiceConfig](https://github.com/StarkAndWayne/bosh-cloudfoundry/blob/master/lib/bosh-cloudfoundry/config/postgresql_service_config.rb) & [RedisServiceConfig](https://github.com/StarkAndWayne/bosh-cloudfoundry/blob/master/lib/bosh-cloudfoundry/config/redis_service_config.rb), respectively.

Create another one for your service, say `MysqlServiceConfig` as a subclass of [ServiceConfig](https://github.com/drnic/bosh-cloudfoundry/blob/master/lib/bosh-cloudfoundry/config/service_config.rb). Make it look something like:

``` ruby
# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module CloudFoundry; module Config; end; end; end

module Bosh::CloudFoundry::Config
  class MysqlServiceConfig < ServiceConfig

    # name that maps into the cf-release's jobs folder
    # for postgresql_gateway and postgresql_node jobs
    # also used as the key into SystemConfig manifest
    def service_name
      "mysql"
    end

    # Add extra configuration properties into the manifest
    # for the gateway, node, and service plans
    def merge_manifest_properties(manifest)
      if any_service_nodes?
        # TODO
      end
    end
  end

  SystemConfig.register_service_config(MysqlServiceConfig)
end
```

Look at the other `ServiceConfig` subclasses for examples of what to put into the `merge_manifest_properties` method.

### Hooking it up

There is one step to hooking up your new class to make it fully integrated. Add the following line to the bottom of the [config.rb](https://github.com/drnic/bosh-cloudfoundry/blob/master/lib/bosh-cloudfoundry/config.rb) file:

``` ruby
require "bosh-cloudfoundry/config/mysql_service_config"
```

This will automatically register the new class with SystemConfig because of the call to `SystemConfig.register_service_config` at the end of the `mysql_service_config.rb` file above.

### Tests should pass

At this point, your tests should pass. 

If they don't then adjust your `merge_manifest_properties` method or perhaps you'll need to override more of the methods provided by `ServiceConfig`.

### Using the service

Now, when your new service should be available via the CLI:

```
$ bosh cf add service mysql
```

## Further explanations

The purpose of the `SystemConfig` class is two-fold:

* represent a portion of the user data in the `SystemConfig` object
* modify a deployment manifest during its rendering process

For each `SystemConfig` manifest there is one of your new `ServiceConfig` objects. It maps to a portion of the `SystemConfig` manifest file; specifically the object stored at the key you added in the section above (for example, `@system_config.mysql`).

For postgresql & redis this object is an array of objects/hashes. Each object/hash represents a cluster of servers/instances/VMs that share the same server flavor and Cloud Foundry service plan. The `"count"` key indicates how many instances should be in the cluster. See section "Extend SystemConfig" above for an example.

### Applying service changes into a deployment manifest

Within this project, the creation of a deployment manifest is called "rendering". It is done by building up a large nested Hash, converting it to a YAML format, then saving to disk. The word "rendering" is also used simply to describe the building up of the large nested Hash that will become a deployment manifest.

During the building process, we delegate to each ServiceConfig object to modify the deployment manifest object. There are four places that each `ServiceConfig` object might perform modifications:

* job templates added/removed to the core job VM (method `add_core_jobs_to_manifest`); for example, `ServiceConfig` will add a service gateway job (e.g. [mysql_gateway](https://github.com/cloudfoundry/cf-release/tree/master/jobs/mysql_gateway)) to the core job
* additional resource pools (method `add_resource_pools_to_manifest`); for example, we will need new servers/instances to provide the mysql service
* additional jobs (method `add_jobs_to_manifest`); we want the additional resource pool servers to become mysql service nodes ([mysql_node](https://github.com/cloudfoundry/cf-release/tree/master/jobs/mysql_node))
* additional shared properties (method `merge_manifest_properties`); for example, to configure the service plans that the service nodes will support, such as "free", and what versions of the actual service (e.g. mysql 5.5) are running.

The first three all have common implementations for all `ServiceConfig` subclasses. It is possible that your service may require already implementations. If so, then reimplement them in your subclass.
