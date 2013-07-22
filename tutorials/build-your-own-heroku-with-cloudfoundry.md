# Build Your Own Heroku With Open Source Cloud Foundry

In this hands on tutorial you will deploy and scale the incredible Cloud Foundry platform-as-a-service in under three hours. Cloud Foundry is sponsored by Pivotal. The do-it-yourself tools in this tutorial are created by Stark & Wayne. Have a great tutorial!

## Requirements

There are four requirements:

* AWS account, with access credentials, and capacity to provision 6 servers & 2 elastic IPs
* Credit on the credit card attached to your AWS account for $1 or so
* Ruby 1.9.3 or Ruby 2.0.0 installed on your local machine
* Internet access

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

This will prompt you for your AWS credentials and then automatically do everything to provision and configure an Ubuntu server ready to be used for deploying a bosh server and subsequent bosh releases.

Now finish the preparation of the inception server (there are outstanding bugs to be fixed for each of the steps below):

```
$ inception ssh
> ubuntu user
$ ssh-keygen
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

```
$ bosh-bootstrap deploy
WARNING! Your target has been changed to `https://IPADDRESS:25555'!

$ bosh target https://IPADDRESS:25555
$ bosh login admin admin
```

## Deploy Cloud Foundry

You're finally ready to deploy and initialize Cloud Foundry.

```
$ bosh prepare cf
$ bosh create cf --ip 1.2.3.4 --name tutorial --security-group cf
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
