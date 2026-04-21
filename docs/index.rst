.. meta::
    :description: Documentation for Canonical's Enterprise Store, which provides an on-premise edge proxy to the Snap Store or a feature limited fully offline Snap Store.

Enterprise Store documentation
==============================

.. attention::

  The Dedicated Snap Store requires a license for deployments of more than 25 devices. Please
  `contact us <https://ubuntu.com/enterprise-store#get-in-touch>`_ for information on pricing.

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

In this documentation
---------------------

.. list-table::
   :widths: 25 75
   :header-rows: 0

   * - **Getting started**
     - :doc:`tutorial/get-started` • :doc:`how-to/devices` • :doc:`how-to/overrides` • :doc:`reference/configuration`
   * - **Air-gapped deployments**
     - :doc:`tutorial/air-gapped-deployment` • :doc:`how-to/airgap`
   * - **Charm support**
     - :doc:`how-to/charmhub-proxy` • :doc:`how-to/airgap-charmhub`
   * - **Dedicated Snap Store support**
     - :doc:`how-to/integrate-a-dedicated-snap-store` • :doc:`how-to/publish-snaps` • :doc:`how-to/build-images`
   * - **API documentation**
     - :doc:`reference/api-authentication` • :doc:`reference/api-overrides`
   * - **Security**
     - :doc:`how-to/security` • :doc:`reference/cryptography`

How this documentation is organised
-----------------------------------

This documentation uses the `Diátaxis documentation structure <https://diataxis.fr/>`_.

* :doc:`tutorial` takes you step-by-step through the setup and operation of the store in both supported modes.
* :doc:`how-to` guides assume you have basic familiarity with Product. They provide focused instructions for specific tasks.
* :doc:`reference` provides detailed information on APIs, configuration, and cryptographic protocols.

.. * Explanation includes topic overviews, background and context and detailed discussion.

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

