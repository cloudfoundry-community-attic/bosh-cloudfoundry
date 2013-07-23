# View system health

Bosh CLI includes the ability to view some health metrics of each server in a deployment.

## Activity

Display the health (CPU, RAM, persistent disk space) of the servers in your Cloud Foundry deployment.

## Tips

1. `bosh vms` shows the list of servers in all deployments
1. `bosh vms tutorial` shows the list of servers in the deployment called `tutorial`
1. `bosh help vms` shows the available options for `bosh vms`

## Solution

Invoke `bosh vms --vitals`:

```
$ bosh vms --vitals
+-----------+---------+---------------+------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
| Job/index | State   | Resource Pool | IPs                          |         Load          | CPU  | CPU  | CPU  | Memory Usage   | Swap Usage | System     | Ephemeral  | Persistent |
|           |         |               |                              | (avg01, avg05, avg15) | User | Sys  | Wait |                |            | Disk Usage | Disk Usage | Disk Usage |
+-----------+---------+---------------+------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
| api/0     | running | small         | 10.159.41.142, 50.19.127.213 | 0.13%, 0.14%, 0.09%   | 0.0% | 0.0% | 0.1% | 14.2% (236.6M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| core/0    | running | small         | 10.170.15.85                 | 0.88%, 1.04%, 0.66%   | 0.0% | 0.0% | 0.1% | 33.9% (561.9M) | 0.0% (0B)  | 49%        | 1%         | n/a        |
| data/0    | running | small         | 10.168.20.214                | 0.00%, 0.06%, 0.09%   | 0.0% | 0.0% | 0.0% | 7.1% (119.2M)  | 0.0% (0B)  | 49%        | 1%         | 4%         |
| dea/0     | running | small         | 10.158.75.168                | 0.00%, 0.01%, 0.05%   | 0.0% | 0.0% | 0.1% | 19.8% (329.2M) | 0.0% (0B)  | 49%        | 2%         | n/a        |
+-----------+---------+---------------+------------------------------+-----------------------+------+------+------+----------------+------------+------------+------------+------------+
```