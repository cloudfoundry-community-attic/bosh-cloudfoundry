# Build Your Own Heroku With Open Source Cloud Foundry

In this hands on tutorial you will deploy and scale the incredible Cloud Foundry platform-as-a-service in under three hours. Cloud Foundry is sponsored by Pivotal. The do-it-yourself tools in this tutorial are created by Stark & Wayne. Have a great tutorial!

## Requirements

There are some requirements:

* AWS account, with access credentials, and capacity to provision 6 servers & 2 elastic IPs
* Credit on the credit card attached to your AWS account for $1 or so
* Ruby 1.9.3 or Ruby 2.0.0 installed on your local machine
* Git (1.8+) installed on your local machine
* Internet access
* About an hour of your time (about 5 minutes of your human activity)
* Doesn't support Windows (lack of rsync for windows)

Optionally:

* Custom DNS (we will use http://xip.io if you do not have one)

## What you will create

In this tutorial you will create 6 servers and 2 elastic IPs:

* 4 m1.small for running Cloud Foundry (1 elastic IP)
* 1 m1.medium for running bosh server
* 1 m1.small for an initial command-line server; we call it the inception server (1 elastic IP)

## What will it cost?

In us-east-1 and us-west-2 ([the two cheapest regions](http://aws.amazon.com/ec2/pricing/#odLinux)) this totals 0.42c per hour or $300 a month.

## Create inception server

If you have a slow local internet (say at home or a conference/workshop) OR if you are deploying to any other region than us-east-1, you should create an inception server.

```
$ gem install inception-server
$ inception deploy
```

This will take about 15 minutes.

This will prompt you for your AWS credentials and then automatically do everything to provision and configure an Ubuntu server ready to be used for deploying a bosh server and subsequent bosh releases.

Now finish the preparation of the inception server (there are outstanding bugs to be fixed for each of the steps below):

```
$ inception ssh
> ubuntu user
$ ssh-keygen -N '' -f ~/.ssh/id_rsa
$ sudo usermod -a -G rvm ubuntu
$ sudo chmod g+w /usr/local/rvm -R
$ exit

$ inception ssh
> ubuntu user
```

## Install bosh projects

The inception server above already installs the following gems. If you skipped the inception server, you will need to run the following commands:

```
$ gem install bosh_cli -v "~> 1.5.0.pre" --source https://s3.amazonaws.com/bosh-jenkins-gems/ 
$ gem install bosh-bootstrap
$ gem install bosh-cloudfoundry --pre
```


## Bootstrap a bosh server

The `bosh-bootstrap` tool (pre-installed on inception server) makes it very simple to get a bosh server running in your AWS region. Within the inception server, a `~/.fog` file is provided with the same credentials you provided above. You type `1` at the first prompt below.

If you are not using an inception server, you will provide your AWS credentials at the first set of prompts.

This section takes about 10 minutes inside us-east-1. It takes about 15 minutes in other regions (as a new AMI must be created).

```
$ bosh-bootstrap deploy
Auto-detected infrastructure API credentials at ~/.fog (override with $FOG)
1. AWS (default)
2. Alternate credentials
Choose an auto-detected infrastructure:  1

Using provider AWS


1. *US East (Northern Virginia) Region (us-east-1)
2. US West (Oregon) Region (us-west-2)
3. US West (Northern California) Region (us-west-1)
4. EU (Ireland) Region (eu-west-1)
5. Asia Pacific (Singapore) Region (ap-southeast-1)
6. Asia Pacific (Sydney) Region (ap-southeast-2)
7. Asia Pacific (Tokyo) Region (ap-northeast-1)
8. South America (Sao Paulo) Region (sa-east-1)
Choose AWS region: 1

Confirming: Using AWS/us-east-1
Acquiring a public IP address... IP.ADD.RE.SS

...

WARNING! Your target has been changed to `https://IP.ADD.RE.SS:25555'!

$ bosh target https://IP.ADD.RE.SS:25555
Your username: admin
Enter password: admin
```

The default username/password is `admin/admin`.

## Upload assets to bosh

```
$ bosh prepare cf
```

The `prepare cf` step takes about 25 minutes to upload the entire set of Cloud Foundry packages (including a base ISO for warden containers) and the base VM stemcell image (700Mb).

## Request a public IP

Whether you have a custom DNS or are going to fall back to the free & flexible http://xip.io (the default), all the traffic into your Cloud Foundry - the main components and the applications it hosts - will go in through one or more public IP addresses.

Visit the [AWS Console for IP Addresses](https://console.aws.amazon.com/ec2/home?region=us-east-1#s=Addresses) (change the region to your target region if not us-east-1), and click "Allocate New Address".

The IP address that is shown will replace all instances of "1.2.3.4" in the remainder of the tutorial below.

## Setup security group

Visit the [AWS Console for Security Groups](https://console.aws.amazon.com/ec2/home?region=us-east-1#s=SecurityGroups) and click "Create Security Group".

Name it `cf`.

Add TCP ports:

* 22 (ssh)
* 80 (http)
* 443 (https)
* 4222 (nats)

## Deploy Cloud Foundry

You're finally ready to deploy and initialize Cloud Foundry.

```
$ bosh create cf --ip 1.2.3.4 --name tutorial --security-group cf
```

If you have a custom DNS that has a `*` A record pointed at your public IP, then use the `--dns` flag:

```
$ bosh create cf --ip 1.2.3.4 --name tutorial --security-group cf --dns mycloud.com
```

The first time you deploy Cloud Foundry it will take approximately 30 minutes. Half of this is compiling the 20+ packages that come with all-included release that was uploaded earlier (`bosh prepare cf`).

If you were to delete this deployment and redeploy it would take less than 15 minutes. (NOTE: you do not have to do this now)

```
$ bosh delete deployment tutorial
$ bosh deploy
```

## Initialize Cloud Foundry

```
$ bosh show cf attributes

$ gem install cf
$ cf target api.1.2.3.4.xip.io
Common password: 6d7fe84f828b
$ cf login admin
Password> 6d7fe84f828b

$ cf create-org me
$ cf create-space production
$ cf switch-space production
```

READY!

## Deploy first application

```
$ mkdir apps
$ cd apps
$ git clone https://github.com/cloudfoundry-community/cf-env.git
$ cd cf-env
$ bundle

$ cf push env
Instances> 1

1: 128M
2: 256M
3: 512M
4: 1G
Memory Limit> 1

Creating env... OK

1: env
2: none
Subdomain> env

1: 1.2.3.4.xip.io
2: none
Domain> 1.2.3.4.xip.io

Creating route env.1.2.3.4.xip.io... OK
Binding env.1.2.3.4.xip.io to env... OK

Create services for application?> n

Save configuration?> n
...

```

Open in a browser: http://env.1.2.3.4.xip.io

## How to tear it all down

You can now tear down Cloud Foundry, bosh server and the inception server. Either:

1. Go into AWS console and delete the servers & AMIs & snapshots & their volumes
2. Follow the following steps to progressively destroy each stage in reverse:

### Delete the Cloud Foundry deployment on bosh

Within the inception server:

```
$ bosh deployments
$ bosh delete deployment tutorial
```

This will delete the four AWS servers that were running Cloud Foundry.

### Delete the bosh server

Within the inception server:

```
$ bosh-bootstrap delete
```

This will delete the bosh server, its attached volume and the AMI.

Finally, exit the inception server and delete it:

```
$ inception delete
```
