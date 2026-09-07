---
title: Deploy the Enterprise Store as a charm
description: Deploy and manage the Enterprise Store with Juju in proxy, offline, or highly available configurations.
---

# Deploy the Enterprise Store as a charm

The `enterprise-store` charm installs and manages the Enterprise Store snap
with Juju. It provides declarative configuration and supports multiple units
for high availability. The charm is available from
[Charmhub](https://charmhub.io/enterprise-store) and requires Juju 3.x.

Use proxy mode when the units can reach the Snap Store. Use offline mode for an
air-gapped deployment, supplying the installation snaps as a resource and using
S3-compatible blob storage. Add HAProxy and multiple units to either mode for a
highly available deployment.

| **How-to guide** | Get stuff done |
|---|---|
| [Deploy in proxy mode](deploy-charmed-proxy.md) | Deploy the default online proxy configuration |
| [Deploy in offline mode](deploy-charmed-offline.md) | Deploy with an offline bundle and S3 storage |
| [Deploy for high availability](deploy-charmed-ha.md) | Run multiple units behind HAProxy |

For a guided first deployment, follow {doc}`Get started with a charmed
Enterprise Store </tutorial/charmed-deployment>`. For exact charm options and
interfaces, see the {doc}`Enterprise Store charm reference </reference/charm>`.

```{toctree}
:hidden:
:maxdepth: 1

Deploy in proxy mode <deploy-charmed-proxy>
Deploy in offline mode <deploy-charmed-offline>
Deploy for high availability <deploy-charmed-ha>
```
