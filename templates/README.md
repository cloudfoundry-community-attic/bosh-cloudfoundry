# Deployment file templates

Within each subfolder are templates used to generate deployment files that tell bosh how to deploy Cloud Foundry.

The subfolders are nested as follows:

```
minimum cf-release version / cpi / size
```

For example:

* v132/aws/dev
* v132/aws/dev
* v140/openstack/production

## Release Versions

In the above examples, if your deployment will use `cf-release` v132 through to v139 then it would use the `v132` subfolder. If it will use v140 onwards then it would use `v140` subfolder.

This allows new gems to be released that support older cf-releases.
