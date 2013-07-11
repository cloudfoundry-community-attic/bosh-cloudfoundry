# Small deployment of Cloud Foundry on OpenStack

The plan for a small deployment is to colocate everything on a single VM; and allow for scaling in one direction - more/bigger DEAs.

This cannot currently be implemented until a final release of [cf-release](https://github.com/cloudfoundry/cf-release) is published that includes `properties` in each job's `spec` file.
