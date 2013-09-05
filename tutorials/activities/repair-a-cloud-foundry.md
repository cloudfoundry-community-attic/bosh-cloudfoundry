# Overview

BOSH is capable of repairing certain issues with your deployments, for example if a VM dies and needs rebuilding.

## Cloud Check

First, let's take a look at my BOSH Cloud Foundry deployment:

```
$ bosh vms
Deployment `cf'

Director task 151

Task 151 done

+---------------------------+--------------------+---------------+-------------------------------+
| Job/index                 | State              | Resource Pool | IPs                           |
+---------------------------+--------------------+---------------+-------------------------------+
| unknown/unknown           | unresponsive agent |               |                               |
| api/0                     | running            | small         | 10.238.151.60, 54.221.248.230 |
| core/0                    | running            | small         | 10.151.15.70                  |
| data/0                    | running            | small         | 10.151.108.188                |
| dea/0                     | running            | small         | 10.151.120.68                 |
| gateways/0                | running            | medium        | 10.179.15.18                  |
| memcached_service_node/0  | running            | medium        | 10.178.11.201                 |
| mongodb_service_node/0    | running            | medium        | 10.152.151.84                 |
| postgresql_service_node/0 | running            | medium        | 10.178.10.187                 |
| redis_service_node/0      | running            | medium        | 10.164.102.90                 |
+---------------------------+--------------------+---------------+-------------------------------+

VMs total: 10
```

Oh, it looks like one of my vm's has died! In this case, I just terminated it on AWS. How do I bring it back up?  Enter stage right, `bosh cloudcheck`.

First, let's check I'm targeting the right deployment.

```
$ bosh deployment bosh-workspace/deployments/cf/cf.yml
Deployment set to `/home/ubuntu/bosh-workspace/deployments/cf/cf.yml'
```

Now let's check it with BOSH.

```
$ bosh cloudcheck
Performing cloud check...

Director task 154

Scanning 10 VMs
  checking VM states (00:00:15)
  9 OK, 0 unresponsive, 1 missing, 0 unbound, 0 out of sync (00:00:00)
Done                    2/2 00:00:15

Scanning 6 persistent disks
  looking for inactive disks (00:00:00)
  6 OK, 0 inactive, 0 mount-info mismatch (00:00:00)
Done                    2/2 00:00:00

Task 154 done
Started         2013-09-05 19:45:28 UTC
Finished        2013-09-05 19:45:43 UTC
Duration        00:00:15

Scan is complete, checking if any problems found...

Found 1 problem
```

That's nice, it found my problem. Now it offers me solutions to each problem it found (it could be multiple if say a piece of hardware died that had multiple vm's running on it.

```
Problem 1 of 1: VM with cloud ID `i-24cfa948' missing.
  1. Ignore problem
  2. Recreate VM using last known apply spec
  3. Delete VM reference (DANGEROUS!)
Please choose a resolution [1 - 3]: 2

Below is the list of resolutions you've provided
Please make sure everything is fine and confirm your changes

  1. VM with cloud ID `i-24cfa948' missing.
     Recreate VM using last known apply spec

Apply resolutions? (type 'yes' to continue): yes
Applying resolutions...

Director task 155

Applying problem resolutions
  missing_vm 86: Recreate VM using last known apply spec (00:01:47)
Done                    1/1 00:01:47

Task 155 done
Started         2013-09-05 19:46:53 UTC
Finished        2013-09-05 19:48:40 UTC
Duration        00:01:47
Cloudcheck is finished
```

There we go, all fixed. Here's what our vm's look like now. All fixed:

```
Deployment `cf'

Director task 156

Task 156 done

+---------------------------+---------+---------------+-------------------------------+
| Job/index                 | State   | Resource Pool | IPs                           |
+---------------------------+---------+---------------+-------------------------------+
| api/0                     | running | small         | 10.238.151.60, 54.221.248.231 |
| core/0                    | running | small         | 10.151.15.70                  |
| data/0                    | running | small         | 10.151.108.188                |
| dea/0                     | running | small         | 10.151.120.68                 |
| gateways/0                | running | medium        | 10.179.15.18                  |
| memcached_service_node/0  | running | medium        | 10.178.11.201                 |
| mongodb_service_node/0    | running | medium        | 10.152.151.84                 |
| postgresql_service_node/0 | running | medium        | 10.178.10.187                 |
| redis_service_node/0      | running | medium        | 10.164.102.90                 |
| vblob_service_node/0      | running | medium        | 10.184.12.177                 |
+---------------------------+---------+---------------+-------------------------------+

VMs total: 10
```
