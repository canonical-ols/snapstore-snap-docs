---
title: Configuring snap devices
table_of_contents: true
---

# Snap devices

## Configuring devices

You will need at least snapd 2.30 on your device and access to a
 [registered Snap Store Proxy](register.html).

To configure snapd on a device to talk to the proxy, you need to first
download the signed assertion that allows snapd to trust the proxy:

    curl -s http://<domain>/v2/auth/store/assertions | sudo snap ack /dev/stdin

Retrieve the Store ID using the status command:

    snap-proxy status

And then tell snapd to use that store:

    sudo snap set core proxy.store=<store id>

## Disconnecting devices

If you want to later disconnect a device from the proxy:

    sudo snap set core proxy.store=''

Note that the next time the device refreshes, it will get the upstream
snap revisions (any overrides won't be in effect).
