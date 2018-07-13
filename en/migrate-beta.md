---
title: Migrating from the Beta release
table_of_contents: true
---

# Migrating from the Beta release

The Snap Store Proxy was originally released in beta form as the 'snapstore'
snap.  This has now been renamed to 'snap-store-proxy'.


Migrating the new snap is straightforward, but may involve a few seconds of downtime.


To migrate to the new snap, take the following steps:

First, install the new snap:

    sudo snap install snap-store-proxy

Then, copy across the configuration to the new snap:

    sudo snap get -d snapstore | sudo snap-store-proxy.migrate-from-beta

You can check the new snap's status:

    snap-proxy status

In order to start the new snap, we must first stop the old one:

    sudo snap stop snapstore
    # downtime here
    sudo snap restart snap-store-proxy

And finally, once you're happy with the migration:

    sudo snap remove snapstore
