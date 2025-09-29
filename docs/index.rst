Enterprise Store documentation
==============================

The **Enterprise Store** (formerly Snap Store Proxy) provides an on-premise edge proxy to the general
`Snap Store <https://snapcraft.io/store>`_ for your devices.

Devices are registered with the Proxy, and all communication with the Snap Store will
**flow through the Proxy**, thereby enabling network-restricted devices to access snaps.
Upstream snap **revisions can be overridden** on the Proxy, allowing fine-grained revision
control for your devices. The Proxy furthermore supports air-gapped deployments when
configured in **offline mode**.

The Proxy is an excellent fit for organisations looking for **more control
over updates** to their snaps, or for enterprises that have held back from adopting
snaps until now because of the challenges of operating within a **restricted
network**.

With the Enterprise Store, snaps are as easy-to-use as ever, and administrators
have much greater control over exactly what revisions are installed on each
connected system.

.. grid:: 1
   
   .. grid-item-card:: :doc:`Getting started <tutorial/get-started>`

      A tutorial walking through setup and usage of the store.

   .. grid-item-card:: :doc:`How-to guides <how-to>`

      Step-by-step guides covering key operations and common tasks.

   .. grid-item-card:: :doc:`Reference <reference>`

      Technical information - specifications, APIs, architecture.

For **security** information, see how to :doc:`how-to/security`.

Project and community
---------------------

The Enterprise Store is a member of the Snap Store family. It's a project that welcomes suggestions, fixes and constructive feedback.

* `Get the Enterprise Store as a snap <https://snapcraft.io/enterprise-store>`_
* `Join the Discourse forum <https://forum.snapcraft.io/c/store/16>`_
* `File a bug <https://bugs.launchpad.net/snapstore-server>`_
* `Get support <https://ubuntu.com/support/community-support>`_

Learn more about how the Enterprise Store overcomes challenges presented by
restricted networks and management policies from this
`whitepaper on Enterprise Snap Management <https://ubuntu.com/engage/enterprise-snap-management>`_.

Thinking about deploying the Enterprise Store in your enterprise? `Get in touch! <https://ubuntu.com/core/services/contact-us>`_

.. toctree::
   :maxdepth: 2
   :hidden:

   Tutorial <tutorial>
   How-to <how-to>
   Reference <reference>

