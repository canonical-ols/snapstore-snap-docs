---
title: Deploy a highly available charmed store
description: Scale the Enterprise Store charm and place its units behind the HAProxy charm.
---

# Deploy a highly available charmed store

Run multiple Enterprise Store units behind the HAProxy charm to provide high
availability. First complete either the {doc}`proxy-mode deployment
<deploy-charmed-proxy>` or the {doc}`offline deployment
<deploy-charmed-offline>`, then add the components below. These instructions
require Juju 3.x.

## Choose where to terminate TLS

For a single unit, the Enterprise Store charm can terminate TLS when
`certificate` and `private_key` are set. Set both options to `selfsigned` to
generate a self-signed certificate. For certificate handling guidance, see
{doc}`Enhance Enterprise Store's security <security>`.

For a highly available deployment, integrate with HAProxy and terminate TLS
there. The Enterprise Store units then serve plain HTTP on port 80. The charm
configures the `/_status/check` health check and the snap honours the
`X-Forwarded-Proto` header.

## Front the store with HAProxy

Deploy the HAProxy charm from `2.8/stable`, add a certificate provider, and
create the `haproxy-route` integration:

```bash
juju deploy haproxy --channel 2.8/stable
juju deploy self-signed-certificates
juju integrate haproxy:certificates self-signed-certificates
juju integrate enterprise-store:haproxy-route haproxy:haproxy-route
```

The registration bundle's domain must be HAProxy's public hostname, and its edge
certificate must cover that hostname. Do not set `certificate` or `private_key`
on the Enterprise Store charm while this integration exists; the unit becomes
blocked because HAProxy owns TLS termination.

## Scale out

Add two units to an existing single-unit deployment:

```bash
juju add-unit enterprise-store -n 2
```

The `rollingops-peers` relation coordinates configuration, certificate, and
snap changes so that no more than one unit restarts its services at a time. A
queued unit reports `Waiting for rolling-ops lock` and requires no intervention.

## Deploy with the Juju CLI

Combine the following with the commands for the selected base deployment:

```bash
juju deploy haproxy --channel 2.8/stable
juju deploy self-signed-certificates
juju integrate haproxy:certificates self-signed-certificates
juju integrate enterprise-store:haproxy-route haproxy:haproxy-route
juju add-unit enterprise-store -n 2
```

## Deploy with a Juju bundle

Add these applications and relations to the proxy or offline bundle, and set
the Enterprise Store application to three units:

```yaml
applications:
  haproxy:
    charm: haproxy
    channel: 2.8/stable
    num_units: 1
  self-signed-certificates:
    charm: self-signed-certificates
    num_units: 1
  enterprise-store:
    num_units: 3

relations:
- - haproxy:certificates
  - self-signed-certificates:certificates
- - enterprise-store:haproxy-route
  - haproxy:haproxy-route
```

## Deploy with Terraform

Add these resources to the Terraform configuration for the base deployment.
Replace `base_model` with its model resource name, and set `units = 3` on the
Enterprise Store application.

```hcl
resource "juju_application" "self_signed_certificates" {
  name       = "self-signed-certificates"
  model_uuid = juju_model.base_model.uuid
  charm {
    name = "self-signed-certificates"
  }
}

resource "juju_application" "haproxy" {
  name       = "haproxy"
  model_uuid = juju_model.base_model.uuid
  charm {
    name    = "haproxy"
    channel = "2.8/stable"
  }
}

resource "juju_integration" "haproxy_self_signed" {
  model_uuid = juju_model.base_model.uuid
  application {
    name     = juju_application.haproxy.name
    endpoint = "certificates"
  }
  application {
    name     = juju_application.self_signed_certificates.name
    endpoint = "certificates"
  }
}

resource "juju_integration" "haproxy_route" {
  model_uuid = juju_model.base_model.uuid
  application {
    name     = juju_application.haproxy.name
    endpoint = "haproxy-route"
  }
  application {
    name     = juju_application.enterprise_store.name
    endpoint = "haproxy-route"
  }
}
```

For the snap-level alternative and reverse-proxy considerations, see
{doc}`Enable High-Availability <high-availability>`. See the {doc}`charm
reference </reference/charm>` for exact interface and status details.
