---
title: Configuring snap devices
table_of_contents: true
---

# Snap devices

## Configuring devices

### Prerequisites

* `snapd` ≥ 2.30 on the client device
* Access to a [registered Enterprise Store](register.md)

First, get the *Store URL* and *Store ID* from the Enterprise Store by running:
    
    sudo enterprise-store status

The output will look something like the following:

    Store URL: http://proxy.example.com
    Store DB: ok
    Store ID: 3dqTufgqR25SBaBoCuqCFwLcU01Gp24U
    Status: approved
    Connected Devices (updated daily): 0
    Device Limit: 25
    Internal Service Status:
    memcached: running
    nginx: running
    snapauth: running
    snapdevicegw: running
    snapdevicegw-local: running
    snapproxy: running
    snaprevs: running

Next, fetch and acknowledge the store assertion on the client device by running:

    curl -sL http://proxy.example.com/v2/auth/store/assertions | sudo snap ack /dev/stdin

```{note}
Replace `http://proxy.example.com` with your *Store URL*.
```

Finally, configure `snapd` to use the Enterprise Store on the client device by running:

    sudo snap set core proxy.store=3dqTufgqR25SBaBoCuqCFwLcU01Gp24U

```{note}
Replace `3dqTufgqR25SBaBoCuqCFwLcU01Gp24U` with your *Store ID*.
```

## Disconnecting devices

If you want to later disconnect a device from the proxy:

    sudo snap set core proxy.store=''

Note that the next time the device refreshes, it will get the upstream
snap revisions (any overrides won't be in effect).

## Obtaining serial assertions

Devices without a
[serial assertion](https://docs.ubuntu.com/core/en/reference/assertions/serial)
are able to obtain one when using the Enterprise Store.

If your devices are configured to use a specific `device-service.url` via your
[gadget snap](https://snapcraft.io/docs/gadget-snap), then `snapd` will send the
device registration request to that device service via the Enterprise Store.
This means that you can use a specific serial-vault service to obtain serial
assertions for your devices running behind an Enterprise Store. Make sure that
your Enterprise Store is able to connect to this specific serial-vault service.

```{note}
By default Enterprise Store allows only the
`https://serial-vault-partners.canonical.com` serial-vault requests to pass
through it.
```

Since version 2.19 of the enterprise-store, the
`proxy.device-auth.allowed-device-service-urls` setting can be used to control
the list of allowed device services (Serial Vaults), e.g.:

    sudo enterprise-store config \
        proxy.device-auth.allowed-device-service-urls='["https://sv1.internal", "https://sv2.internal"]'


## Next step

With devices connected to the proxy, you can [create
overrides](overrides.md) to control snap updates on them.
