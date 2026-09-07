---
title: Deploy a charmed store in proxy mode
description: Deploy the Enterprise Store charm in its default online proxy mode with PostgreSQL.
---

# Deploy a charmed store in proxy mode

Proxy mode is the charm's default mode. The unit must be able to reach the Snap
Store to install the Enterprise Store snap and proxy device requests. For a
deployment without internet access, see {doc}`Deploy a charmed store in offline
mode <deploy-charmed-offline>`.

## Prerequisites

You need Juju 3.x and a controller on a machine cloud, such as LXD. See the
[Juju documentation](https://documentation.ubuntu.com/juju/3.6/howto/manage-controllers/)
for controller setup. For a guided local deployment, follow
{doc}`Get started with a charmed Enterprise Store
</tutorial/charmed-deployment>`.

Register the store with `store-admin` against the domain that devices will use:

```bash
store-admin register https://store.example.com
```

Supply the generated `registration_bundle.b64` to the charm. See
{doc}`Registration <register>` for registration concepts.

The charm requires PostgreSQL through the `database` integration. Enable
`btree_gist` on the PostgreSQL charm so that the extension is available:

```bash
juju config postgresql plugin_btree_gist_enable=true
```

## Deploy with the Juju CLI

Charmhub currently publishes the Enterprise Store charm in the `latest/edge`
channel. Deploy and configure it as follows:

```bash
juju deploy postgresql --channel 14/stable
juju config postgresql plugin_btree_gist_enable=true
juju deploy enterprise-store --channel edge
juju integrate postgresql:database enterprise-store:database
juju config enterprise-store \
    registration_bundle="$(cat registration_bundle.b64)"
```

Run `juju status` until the Enterprise Store unit is active, then use
{doc}`Configure a device to use the Enterprise Store <devices>`.

## Deploy with a Juju bundle

Save the following as `bundle.yaml`, replace the registration bundle value, and
deploy it with `juju deploy ./bundle.yaml`:

```yaml
applications:
  postgresql:
    charm: postgresql
    channel: 14/stable
    num_units: 1
    options:
      plugin_btree_gist_enable: true
  enterprise-store:
    charm: enterprise-store
    channel: edge
    num_units: 1
    options:
      registration_bundle: <registration_bundle.b64>

relations:
- - postgresql:database
  - enterprise-store:database
```

## Deploy with Terraform

The following configuration uses the `juju/juju` Terraform provider. Put the
registration bundle beside the Terraform configuration before applying it.

```hcl
terraform {
  required_providers {
    juju = {
      source  = "juju/juju"
      version = "~> 2.2.1"
    }
  }
}

provider "juju" {}

resource "juju_model" "proxy_model" {
  name = "proxy-model"
  cloud {
    name   = "localhost"
    region = "localhost"
  }
}

resource "juju_application" "postgresql" {
  name       = "postgresql"
  model_uuid = juju_model.proxy_model.uuid
  charm {
    name    = "postgresql"
    channel = "14/stable"
  }
  config = {
    plugin_btree_gist_enable = true
  }
}

resource "juju_application" "enterprise_store" {
  name       = "enterprise-store"
  model_uuid = juju_model.proxy_model.uuid
  charm {
    name    = "enterprise-store"
    channel = "edge"
  }
  config = {
    registration_bundle = file("${path.module}/registration_bundle.b64")
  }
}

resource "juju_integration" "database" {
  model_uuid = juju_model.proxy_model.uuid
  application {
    name     = juju_application.postgresql.name
    endpoint = "database"
  }
  application {
    name     = juju_application.enterprise_store.name
    endpoint = "database"
  }
}
```

See the {doc}`charm reference </reference/charm>` for configuration and
integration details.
