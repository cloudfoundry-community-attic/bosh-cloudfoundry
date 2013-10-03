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
Instances> 10

1: 128M
2: 256M
3: 512M
4: 1G
Memory Limit> 128M

Scaling env2... OK
Stopping env2... OK

Preparing to start env2... OK
Checking status of app 'env2'...
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 starting)
   0 of 10 instances running (6 starting, 4 down)
   0 of 10 instances running (3 starting, 7 down)
   3 of 10 instances running (3 running, 7 starting)
   3 of 10 instances running (3 running, 7 starting)
   6 of 10 instances running (6 running, 4 down)
   8 of 10 instances running (8 running, 2 starting)
   9 of 10 instances running (9 running, 1 starting)
   7 of 10 instances running (7 running, 3 down)
   6 of 10 instances running (6 running, 4 down)
   7 of 10 instances running (7 running, 3 down)
```

And it never quite finishes. This is the current sign that there isn't enough capacity for your application's scale.

To scale up the number of DEA servers, edit the following sections of your deployment file (via `bosh edit deploment`).

Increase the `small` resource pool by 2.

``` yaml
resource_pools:
  - name: small
    network: default
    size: 6
    stemcell:
      name: bosh-aws-xen-ubuntu
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

Now scale the app again to 10 instances:

```
$ cf scale env
Instances> 10

1: 128M
2: 256M
3: 512M
4: 1G
Memory Limit> 1 

Scaling env2... OK
Stopping env2... OK

Preparing to start env... OK
Checking status of app 'env2'...
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 down)
   0 of 10 instances running (10 starting)
   0 of 10 instances running (6 starting, 4 down)
   0 of 10 instances running (3 starting, 7 down)
   3 of 10 instances running (3 running, 7 starting)
   3 of 10 instances running (3 running, 7 starting)
   6 of 10 instances running (6 running, 4 down)
   8 of 10 instances running (8 running, 2 starting)
   9 of 10 instances running (9 running, 1 starting)
   7 of 10 instances running (7 running, 3 down)
   6 of 10 instances running (6 running, 4 down)
   7 of 10 instances running (7 running, 3 down)
   6 of 10 instances running (6 running, 4 down)
   7 of 10 instances running (7 running, 3 down)
   6 of 10 instances running (6 running, 4 down)
   7 of 10 instances running (7 running, 3 down)
   6 of 10 instances running (6 running, 4 down)
  10 of 10 instances running (10 running)
Push successful! App 'env2' available at http://env.1.2.3.4.xip.io
```


## Bonus

Why did the two identical DEA servers start one at a time?

Learn about "canaries" in the educational video [BOSH: What, How, When](http://drnicwilliams.com/2012/05/15/bosh-what-how-when/ "Dr Nic's   BOSH: What, How, When").
