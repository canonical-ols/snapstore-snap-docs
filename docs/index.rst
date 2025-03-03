Enterprise Store documentation
==============================

The **Enterprise Store** provides an on-premise edge proxy to the general
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


.. rubric:: In this documentation

.. grid:: 1 1 2 2
   

   .. grid-item:: :doc:`How-to guides <en/how-to>`

      Step-by-step guides covering key operations and common tasks.

   .. grid-item:: :doc:`Reference <en/reference>`

      Technical information - specifications, APIs, architecture.


Project and community
---------------------

The Enterprise Store is a member of the Snap Store family. It's a project that welcomes suggestions, fixes and constructive feedback.

* `Get the Enterprise Store as a snap <https://snapcraft.io/snap-store-proxy>`_
* `Join the Discourse forum <https://forum.snapcraft.io/c/store/16>`_
* `File a bug <https://bugs.launchpad.net/snapstore-server>`_
* `Get support <https://ubuntu.com/support/community-support>`_

Thinking about deploying the Enterprise Store in your enterprise? `Get in touch! <https://ubuntu.com/core/services/contact-us>`_

.. toctree::
   :maxdepth: 2
   :hidden:

   How-to <en/how-to>

.. toctree::
   :maxdepth: 2
   :hidden:

   Reference <en/reference>
