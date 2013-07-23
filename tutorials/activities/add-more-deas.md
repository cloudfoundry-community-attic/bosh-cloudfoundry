# Add more DEA servers

In the initial "tutorial" deployment there is a single DEA server - a small instance with approximately 2G of RAM. This isn't very much and you won't be able to run many applications.

One quick way to increase the amount of RAM available for applications is to run more DEA servers.

## Activity

Scale the "env" tutorial application to exceed the 2G of RAM available and see the error.

Edit the deployment file (as of writing there is not yet a nice way to do this via bosh-cloudfoundry) to increase the number of DEA servers to 3.

## Tips

1. Scale a running Cloud Foundry app using `cf scale`
1. To edit your deployment file run `bosh edit deployment`
1. If you increase the `instances:` of a job, also increase the `size:` of the corresponding `resource_pool`

## Solution

To scale the app and run out of RAM:

```
$ cf scale env
Instances> 20

1: 128M
2: 256M
3: 512M
4: 1G
Memory Limit> 128M

Scaling env... FAILED
CFoundry::AppMemoryQuotaExceeded: 100005: You have exceeded your organization's memory limit. Please login to your account and upgrade. If you are trying to scale down and you are receiving this error, you can either delete an app or contact support.
cat ~/.cf/crash # for more details
```

To scale up the number of DEA servers, edit the following sections of your deployment file (via `bosh edit deploment`).

Increase the `small` resource pool by 2.

``` yaml
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

Increase the 'dea' job by 2.

In `jobs:`

``` yaml
- name: dea
  release: cf-release
  template:
    - dea_next
  instances: 3
  resource_pool: small
  networks:
    - name: default
      default: [dns, gateway]
```

To apply the changes run `bosh deploy`.

```
$ bosh deploy
...
Resource pools
small
  changed size: 
    - 4
    + 6

Networks
No changes

Jobs
dea
  changed instances: 
    - 1
    + 3
```

Type "yes" and Enter.

It will boot up two new servers and run the DEA job on them. Each DEA job will automatically join Cloud Foundry by announcing itself to the Cloud Controller.

```
Creating bound missing VMs
small/0, small/1                    |                        | 0/2 00:00:04  ETA: --:--:--          
```

And later...

```
Updating job dea
dea/1 (canary)                      |ooooooooo               | 0/2 00:00:04  ETA: --:--:--          
```


## Bonus

Why did the two identical DEA servers start one at a time?

Learn about "canaries" in the educational video [BOSH: What, How, When](http://drnicwilliams.com/2012/05/15/bosh-what-how-when/ "Dr Nic's   BOSH: What, How, When").
