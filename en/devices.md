---
title: Configuring snap devices
table_of_contents: true
---

# Snap devices

## Configuring devices

You will need at least snapd 2.30 on your device and access to a
 [registered Snap Store Proxy](register.html).

To configure snapd on a device to talk to the proxy, you need to `snap
ack` the signed assertion that allows snapd to trust the proxy, e.g.:

    curl -sL http://<domain>/v2/auth/store/assertions | sudo snap ack /dev/stdin

Once snapd knows about the store assertion, you then have to configure it to use the proxy:

    sudo snap set core proxy.store=STORE_ID

You can retrieve the `STORE_ID` using the status command on the Proxy server:

    snap-proxy status

## Disconnecting devices

If you want to later disconnect a device from the proxy:

    sudo snap set core proxy.store=''

Note that the next time the device refreshes, it will get the upstream
snap revisions (any overrides won't be in effect).

## Obtaining serial assertions

Devices without a
[serial assertion](https://docs.ubuntu.com/core/en/reference/assertions/serial)
are able to obtain one when using the Snap Store Proxy.

If your devices are configured to use a specific `device-service.url` via your
[gadget snap](https://snapcraft.io/docs/gadget-snap), then `snapd` will send the
device registration request to that device service via the Snap Store Proxy.
This means that you can use a specific serial-vault service to obtain serial
assertions for your devices running behind a Snap Store Proxy. Make sure that
your Snap Store Proxy is able to connect to this specific serial-vault service.

!!! NOTE:
    Currently Snap Store Proxy allows only the
    `https://serial-vault-partners.canonical.com`
    serial-vault requests to pass through it.
    This means custom serial-vaults are not supported at the moment.

## Next step

With devices connected to the proxy, you can [create
overrides](overrides.md) to control snap updates on them.
