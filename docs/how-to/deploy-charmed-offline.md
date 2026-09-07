---
title: Deploy a charmed store in offline mode
description: Deploy the Enterprise Store charm in offline mode with an installation bundle and S3-compatible storage.
---

# Deploy a charmed store in offline mode

In offline mode, the charm installs the Enterprise Store from an attached
`store-bundle` resource rather than the Snap Store. Set `offline: true` and
integrate the charm with an S3-compatible storage provider. The unit remains
blocked until the `s3-credentials` integration is established.

## Prerequisites

You need Juju 3.x, a controller on a machine cloud, and PostgreSQL with
`btree_gist` enabled:

```bash
juju deploy postgresql --channel 14/stable
juju config postgresql plugin_btree_gist_enable=true
```

## Prepare the offline store bundle

On an internet-connected machine, use `store-admin` to register the store and
produce `offline-snap-store.tar.gz`:

```bash
store-admin register --offline https://offline.example.com
```

The archive contains an `offline-snap-store/` directory with the `snapd`,
`core22`, and `enterprise-store` snaps and matching assertions. It also contains
`proxy.assert` and `registration_bundle.b64`. For more information about
registration and post-deployment operations such as `push-snap`, see
{doc}`Offline store (air-gapped mode) <airgap>`.

## Attach the store-bundle resource

Attach the archive at deployment time, as shown below, or attach it to an
existing application:

```bash
juju attach-resource enterprise-store \
    store-bundle=./offline-snap-store.tar.gz
```

The charm installs all three snaps together. On first bootstrap only, it writes
`proxy.assert` to
`/var/snap/enterprise-store/common/nginx/airgap/store.assert`. Attaching a later
bundle does not reapply the store assertion.

## Configure the registration bundle

Extract the registration bundle and provide its contents as charm
configuration:

```bash
tar xzf offline-snap-store.tar.gz \
    offline-snap-store/registration_bundle.b64
juju config enterprise-store \
    registration_bundle="$(cat offline-snap-store/registration_bundle.b64)"
```

## Configure S3 storage

Deploy `s3-integrator`, then provide its credentials through a Juju secret.
Replace each placeholder with the value for your S3 service:

```bash
juju deploy s3-integrator --channel 2/stable
juju add-secret s3-creds \
    access-key="<access-key>" secret-key="<secret-key>"
juju grant-secret s3-creds s3-integrator
juju config s3-integrator \
    credentials=secret:<secret-id> \
    endpoint=<s3-endpoint> \
    bucket=<bucket-name>
```

The integration maps S3 data to the snap configuration as follows and sets
`proxy.storage.backend` to `s3`:

| `s3-integrator` field | Enterprise Store snap configuration |
|---|---|
| `access-key` | `proxy.storage.s3.access-key-id` |
| `secret-key` | `proxy.storage.s3.secret-access-key` |
| `bucket` | `proxy.storage.s3.unscanned-container-name` |
| `bucket` | `proxy.storage.s3.scanned-container-name` |
| `endpoint` | `proxy.storage.s3.server-url` |
| `region` | `proxy.storage.s3.region` |
| `s3-uri-style` | `proxy.storage.s3.use-path-style` |

## Deploy with the Juju CLI

Charmhub currently publishes the Enterprise Store charm in the `latest/edge`
channel:

```bash
juju deploy enterprise-store --channel edge \
    --config offline=true \
    --resource store-bundle=./offline-snap-store.tar.gz
juju deploy s3-integrator --channel 2/stable
juju integrate postgresql:database enterprise-store:database
juju integrate s3-integrator enterprise-store:s3-credentials
juju config enterprise-store \
    registration_bundle="$(cat offline-snap-store/registration_bundle.b64)"
```

Configure the S3 credentials and endpoint as described above, then wait for
`juju status` to report the Enterprise Store unit as active.

## Deploy with a Juju bundle

```yaml
applications:
  postgresql:
    charm: postgresql
    channel: 14/stable
    num_units: 1
    options:
      plugin_btree_gist_enable: true
  s3-integrator:
    charm: s3-integrator
    channel: 2/stable
    num_units: 1
  enterprise-store:
    charm: enterprise-store
    channel: edge
    num_units: 1
    options:
      offline: true
      registration_bundle: <registration_bundle.b64>
    resources:
      store-bundle: ./offline-snap-store.tar.gz

relations:
- - postgresql:database
  - enterprise-store:database
- - s3-integrator
  - enterprise-store:s3-credentials
```

After deploying the bundle, configure the `s3-integrator` credentials and
endpoint.

## Deploy with Terraform

The Juju Terraform provider does not manage local file resources directly. Use
a `null_resource` to attach the bundle after declaring the applications and
integrations. Provider releases before 2.2.1 cannot deploy a purely local charm,
so this example uses the charm published on Charmhub.

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

resource "juju_model" "offline_model" {
  name = "offline-model"
  cloud {
    name   = "localhost"
    region = "localhost"
  }
}

resource "juju_application" "postgresql" {
  name       = "postgresql"
  model_uuid = juju_model.offline_model.uuid
  charm {
    name    = "postgresql"
    channel = "14/stable"
  }
  config = { plugin_btree_gist_enable = true }
}

resource "juju_application" "enterprise_store" {
  name       = "enterprise-store"
  model_uuid = juju_model.offline_model.uuid
  charm {
    name    = "enterprise-store"
    channel = "edge"
  }
  config = {
    registration_bundle = file("${path.module}/offline-snap-store/registration_bundle.b64")
    offline             = true
  }
}

resource "juju_application" "s3_integrator" {
  name       = "s3-integrator"
  model_uuid = juju_model.offline_model.uuid
  charm {
    name    = "s3-integrator"
    channel = "2/stable"
  }
}

resource "juju_integration" "database" {
  model_uuid = juju_model.offline_model.uuid
  application {
    name     = juju_application.postgresql.name
    endpoint = "database"
  }
  application {
    name     = juju_application.enterprise_store.name
    endpoint = "database"
  }
}

resource "juju_integration" "s3_credentials" {
  model_uuid = juju_model.offline_model.uuid
  application {
    name     = juju_application.enterprise_store.name
    endpoint = "s3-credentials"
  }
  application {
    name     = juju_application.s3_integrator.name
    endpoint = "s3-credentials"
  }
}

resource "null_resource" "store_bundle" {
  triggers = {
    app_id      = juju_application.enterprise_store.id
    bundle_hash = filemd5("${path.module}/offline-snap-store.tar.gz")
  }
  provisioner "local-exec" {
    command = "juju attach-resource enterprise-store store-bundle=${path.module}/offline-snap-store.tar.gz"
  }
}
```

For a multi-unit deployment, continue with {doc}`Deploy a highly available
charmed store <deploy-charmed-ha>`. See the {doc}`charm reference
</reference/charm>` for resource and integration details.
