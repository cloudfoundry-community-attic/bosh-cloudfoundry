# Which bits are running where?

Within your running "tutorial" deployment are the following components of Cloud Foundry:

* Router
* Cloud Controller
* DEA
* NATS (message bus)
* UAA (User Account and Authentication)
* Health manager
* Postgresql
* NFS

## Activity

Your "tutorial" deployment has 4 VMs:

```
$ bosh vms
+-----------+---------+---------------+-------------------------+
| Job/index | State   | Resource Pool | IPs                     |
+-----------+---------+---------------+-------------------------+
| api/0     | running | small         | 10.159.41.142, 1.2.3.4  |
| core/0    | running | small         | 10.170.15.85            |
| data/0    | running | small         | 10.168.20.214           |
| dea/0     | running | small         | 10.158.75.168           |
+-----------+---------+---------------+-------------------------+
```

Which components are running on which VMs?

## Tips

1. to edit your deployment file run `bosh edit deployment`
1. the VMs in the running deployment above are called `jobs`

## Solution

* `data/0` - `postgres`, `debian_nfs_server`
* `core/0` - `nats`, `health_manager_next`, `uaa`
* `api/0` - `cloud_controller_ng`, `gorouter`
* `dea/0` - `dea_ng`

