---
title: Introduction
---

# Snap Store Proxy documentation

The Snap Store Proxy provides an on-premise edge proxy to the general
[Snap Store](https://snapcraft.io/store) for your devices. Devices are
registered with the proxy, and all communication with the Store will flow
through the proxy.

!!! NOTE:
    In order to serve its client devices, a Snap Store Proxy needs to be online
    and connected to the general [Snap Store](https://snapcraft.io/store). This
    is a requirement, even though Snap Store Proxy caches downloaded snap files,
    which substantially reduces internet traffic. There's currently no generally
    available offline mode for the Snap Store Proxy itself. See the up-to-date
    [Network requirements for Snappy](https://forum.snapcraft.io/t/network-requirements-for-snappy/5147)
    post for a list of domains Snap Store Proxy needs access to.

## Feature list

* Network control

    * Provides a means to access the Snap Store for devices with restricted
      network access

    * Snap Store Proxy can communicate with the Snap Store directly or through
      an HTTPS forward proxy

* Caching of the downloaded snaps

* [Overriding revisions](overrides.md) of specific snaps for all connected
  devices

* Management options

    * `snap-proxy` CLI interface included with the
      [Snap Store Proxy](https://snapcraft.io/snap-store-proxy) snap

    * Remote management using the
      [Snap Store Proxy Client](https://snapcraft.io/snap-store-proxy-client)
      or a [RESTful API](api-overrides.md).

## Whitepaper

Learn more about how the Snap Store Proxy overcomes challenges presented by
restricted networks and management policies from this
[whitepaper on Enterprise Snap Management](https://ubuntu.com/engage/enterprise-snap-management).
