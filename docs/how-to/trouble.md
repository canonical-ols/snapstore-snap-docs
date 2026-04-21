---
title: Troubleshooting the Enterprise Store
table_of_contents: true
description: Diagnose and resolve common Enterprise Store issues by checking connections, reviewing logs, and verifying configuration.
---

# Troubleshooting

To check egress firewall rules:

    enterprise-store check-connections

Logs are available in systemd logs:

    snap logs enterprise-store

or:

    journalctl -u 'snap.enterprise-store.*'


The enterprise-store snap includes multiple systemd services, the status of
which can be checked with:

    enterprise-store status

Or:

    sudo systemctl status -a 'snap.enterprise-store.*'

To restart the enterprise-store services, run:

    sudo snap restart enterprise-store

The download cache is at `/var/snap/enterprise-store/current/nginx/cache`.
The default limit is 2GB, this can be changed with:

    sudo enterprise-store config proxy.cache.size=4096  # in mb

The Enterprise Store can be scrubbed from a system using

    sudo snap remove enterprise-store --purge

Confirm that data is removed:

    sudo snap saved enterprise-store

If there are any snapshots for enterprise-store, remove them manually:

    sudo snap forget <Set-number>

.. note::
   Without the `--purge` flag snapshots will be kept for 31 days.

## Moving to a new hostname

If you need to move the enterprise-store to a new hostname, you can do:

    sudo enterprise-store config proxy.domain=NEWDOMAIN
    sudo enterprise-store reregister

This perform another registration cycle and update the assertion file
with the new domain name.
Then you will need to run `snap ack` on the client devices to replace the existing assertion.

## Documentation

This documentation is shipped with the snap, and available at:

    http://MY-PROXY/docs/

## Bug / vulnerability reporting

Please file bugs against [this project on Launchpad](https://bugs.launchpad.net/snapstore). Details on reporting vulnerabilities and security issues are detailed in the [Ubuntu Disclosure Policy](https://ubuntu.com/security/disclosure-policy).

### Known issues

1. The `snap download` command doesn't do the download of the snap through
   `snapd` service, and therefore doesn't know about the Enterprise Store
   and will try to fetch the snap directly. [Forum
   thread](https://forum.snapcraft.io/t/improvements-in-snap-download/1422)
2. Need to be root when configuring the snap proxy.
   [Forum thread](https://forum.snapcraft.io/t/should-snapctl-set-in-apps-trigger-the-configure-hook/2032/7)
