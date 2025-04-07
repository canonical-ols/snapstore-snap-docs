---
title: Feature list
---

# Feature list

* Network control

    * Provides a means to access the Snap Store for devices with restricted
      network access

    * Enterprise Store can communicate with the Snap Store directly or through
      an HTTPS forward proxy

* Caching of the downloaded snaps

* [Overriding revisions](../how-to/overrides.md) of specific snaps for all connected
  devices

* Management options

    * `snap-proxy` CLI interface included with the
      [Enterprise Store](https://snapcraft.io/snap-store-proxy) snap

    * Remote management using the
      [Enterprise Store Client](https://snapcraft.io/snap-store-proxy-client)
      or a [RESTful API](api-overrides.md).

* [Offline mode](../how-to/airgap.md).

```{note}
Unless it is deliberately set up as [offline](../how-to/airgap.md), an Enterprise Store needs to be online
and connected to the general [Snap Store](https://snapcraft.io/store). This
is a requirement, even though Enterprise Store caches downloaded snap files,
which substantially reduces internet traffic. There's currently no generally
available offline mode for the Enterprise Store itself. See
[Network Connectivity](../how-to/install.md#network-connectivity) for the
`snap-proxy check-connections` command and the up-to-date
[Network requirements for Snappy](https://forum.snapcraft.io/t/network-requirements-for-snappy/5147)
post for a list of domains Enterprise Store needs access to.
```
