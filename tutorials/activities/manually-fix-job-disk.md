# Manually fix a job disk

BOSH automates everything, so when that automation goes awry then it can be difficult to think through how to fix it manually.

In this activity, you will imagine that the persistent disk attached to the Postgresql & NFS server (`data/0`) was formatted too small and resizing it via BOSH has not worked successfully.

Fix this issue.


## Tips

1. Avoid adding servers (job instances) in the current deployment. When things get messy, the deployment locks can get in the way.
1. Create clones of a deployment by copying the deployment file, giving it a new `name:` value, and changing any external values (such as floating IP addresses, subnet references).
1. rsync copies files very well
1. BOSH job instances are not created to allow SSH access (for rsync) between them.
1. Use the `vcap` user on source and target job instances rather than the `bosh ssh` generated user or `root` user.
1. `ssh-keygen` can create a new public/private key pair for a job instance's `vcap` user to allow SSH (rsync) to other VMs.
1. Copy the `/home/vcap/.ssh/id_rsa.pub` file contents into the bottom of target job instance's `/home/vcap/.ssh/authorized_keys` files to allow SSH (and rsync) connects from a job instance to target job instances.
1. To copy the persistent disk of a job instance to another VM between `vcap` users: `rsync /var/vcap/store/* TARGET_IP:/var/vcap/store/`
1. You can force delete the original faulty job instance & disk via your IaaS's console or CLIs.
1. Running `bosh cck` will offer to recreate the job instance and attached disk.
1. Reverse the rsync to restore the persistent disk contents: `rsync TARGET_IP:/var/vcap/store/* /var/vcap/store`
