# Move the Cloud Controller into its own VMs and scale it

In the default "medium" deployment (used in the step-by-step tutorial), the Cloud Controller is collocated with the front-end router on the `api/0` server.

## Activity

Manually edit your deployment to run the Cloud Controller on its own dedicated server. Then run two Cloud Controller servers. Then revert back to running it on the same server as the router (and which also has the public IP attached).

## Tips

1. to edit your deployment file run `bosh edit deployment`
1. to make a backup of your deployment file, get its path from `bosh deployment`
1. to apply the new deployment file changes run `bosh deploy`
1. the Cloud Controller is the `cloud_controller_ng` job template within the `api` job in the deployment file.
1. remove `- cloud_controller_ng` from the `name: api` job; and create a new job that looks similar to the `name: core` job
1. your new `cloud_controller` job needs a `properties.db` set to `databases` to tell it where in the `properties` to find the database connections. The `api` job no longer needs these properties.


## Solution

Add the `cloud_controller` job above the `api` job; and remove `cloud_controller_ng` from the `api` job.

Convert the following `api` job:

``` yaml
- name: api
  release: cf-release
  template:
    - cloud_controller_ng
    - gorouter
  instances: 1
  resource_pool: small
  networks:
  - name: default
    default:
    - dns
    - gateway
  - name: floating
    static_ips:
    - 50.19.127.213
  properties:
    db: databases
```

Into the following two jobs:

``` yaml
jobs:
...

- name: cloud_controller
  release: cf-release
  template:
    - cloud_controller_ng
  instances: 2
  resource_pool: small
  networks:
  - name: default
    default:
    - dns
    - gateway
  properties:
    db: databases

- name: api
  release: cf-release
  template:
    - gorouter
  instances: 1
  resource_pool: small
  networks:
  - name: default
    default:
    - dns
    - gateway
  - name: floating
    static_ips:
    - 1.2.3.4
```

And increase the `small` resource pool by two (for the two `cloud_controller` job servers above):

```
resource_pools:
  - name: small
    network: default
    size: 6
    stemcell:
      name: bosh-stemcell
      version: latest
    cloud_properties:
      instance_type: m1.small
```

To change back to collocated Cloud Controller and Router, copy back in your original deployment file; and `bosh deploy`.
