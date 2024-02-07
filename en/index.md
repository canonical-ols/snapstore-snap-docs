---
title: Introduction
---

# Snap Store Proxy documentation

The **Snap Store Proxy** provides an on-premise edge proxy to the general
[Snap Store](https://snapcraft.io/store) for your devices.

Devices are registered with the Proxy, and all communication with the Snap Store will
**flow through the Proxy**, thereby enabling network-restricted devices to access snaps.
Upstream snap **revisions can be overriden** on the Proxy, allowing fine-grained revision
control for your devices. The Proxy furthermore supports air-gapped deployments when
configured in **offline mode**.

The Proxy is an excellent fit for organisations looking for **more control
over updates** to their snaps, or for enterprises that have held back from adopting
snaps until now because of the challenges of operating within a **restricted
network**.

With the Snap Store Proxy, snaps are as easy-to-use as ever, and administrators
have much greater control over exactly what revisions are installed on each
connected system.

---

## In this documentation

|                                                                                                                 |                                                                                               |
|-----------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| [Tutorials](tutorial.md)</br> Get started - a hands-on introduction to the Snap Store Proxy for new users </br> | [How-to guides](how-to.md) </br> Step-by-step guides covering key operations and common tasks |
| [Reference](reference.md) </br> Technical information - specifications, APIs, architecture                      | [Explanation](explanation.md) </br> Concepts - discussion and clarification of key topics     |

---

## Project and community

The Snap Store Proxy is a member of the Snap Store family. It's a project that welcomes suggestions, fixes and constructive feedback.

* [Get the Snap Store Proxy as a snap](https://snapcraft.io/snap-store-proxy)
* [Join the Discourse forum](https://forum.snapcraft.io/c/store/16)
* [File a bug](https://bugs.launchpad.net/snapstore-server)
* [Get support](https://ubuntu.com/support/community-support)

Thinking about deploying the Snap Store Proxy in your enterprise? [Get in touch!](https://ubuntu.com/core/services#get-in-touch)
