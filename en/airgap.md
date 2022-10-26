---
title: Offline store (air-gapped mode)
table_of_contents: true
---

# Offline store (air-gapped mode)

By default, the Snap Store Proxy operates in online mode. It acts as a smart
proxy to the general SaaS Snap Store.

Snap Store Proxy can operate in offline mode and act as a local Snap Store
(on-prem store), meaning it can be deployed in networks that are disconnected
from the internet.

The intended use case for this mode are network restricted environments where no
outside traffic is allowed or possible.

## Overview

Client devices connect to the offline store. The local store doesn't directly
contact the general SaaS Snap Store nor the internet.

Proxy operators side-load all necessary snaps into their local store by
exporting them from the SaaS store first and then importing into their offline
store.

## Installation

If the target host has internet access at the time of installation, then the
regular [installation](install.md) and [registration](register.md) can be used
followed by airgap mode activation:

```bash
sudo snap-proxy enable-airgap-mode
```

!!! Negative "":
    Even though it's possible to enable airgap mode for an online proxy, it's
    only advised to do so during the installation phase when no devices are yet
    [connected](devices.md) to the proxy. Deactivating and activating airgap
    mode while it's already serving clients will have undesirable and not
    clearly defined consequences for the devices that were connected to it
    before the mode switch as well as for the snap-store-proxy instance itself.

### Offline installation

To deploy an offline store (Snap Store Proxy in air-gapped mode) to a machine
without internet access it's possible to register it using a separate machine
first and install the resulting package on the target machine.

Air-gapped Snap Store Proxy operators first have to register their offline proxy
on a **machine with internet access**. This can be done using the `store-admin`
snap:

```bash
sudo snap install store-admin
```

On the same machine, register the store and obtain a tarball for installation on
an offline host (partly pre-configured as well):


```bash
# You'll be prompted to authenticate with your Ubuntu SSO authentication.
store-admin register --offline <target-http-location-of-the-store>
```

!!! Warning "":
    Full value of the target location, eg `https://snaps.internal`, will be encoded
    in an assertion file used for instructing client devices to connect to this
    store. It's important to decide if http or https will be used and what the host
    name will be at the point of registration.

The result of the above is a tarball `offline-snap-store.tar.gz` that is then
moved to the target host machine for the offline store.

The target machine (the air-gapped Snap Store Proxy host) should have network
access to a [properly configured PostgreSQL database](install.md#database).

You will need the `offline-snap-store.tar.gz` bundle from the registration step
to continue with installation.

The script below illustrates the installation process on the target air-gapped
machine. Please note that the following variables need to be set appropriately:

* `POSTGRESQL_CONN_STRING` - the connection string to a
  [properly set up PostgreSQL database](install.md#database)

```bash
#!/bin/bash

set -eu

# PostgreSQL connection string to the Snap Store Proxy database.
POSTGRESQL_CONN_STRING="${POSTGRESQL_CONN_STRING}"

tar xvzf offline-snap-store.tar.gz
cd offline-snap-store
sudo ./install.sh

sudo snap-store-proxy config proxy.db.connection="$POSTGRESQL_CONN_STRING"

sudo snap-store-proxy enable-airgap-mode

sudo snap-store-proxy status
```

If the registered store's location was an HTTPS one, follow the
[HTTPS setup](https.md) instructions to configure the TLS certificate.


## Usage

### Side-loading snaps

It's possible to export snaps from the upstream Snap Store and import them into
their on-prem store. These will be the only snaps (and their revisions)
available for installation from the on-prem store.

#### Exporting snaps

Example of exporting `jq` and `htop` snaps on a **machine with internet access**
using the `store-admin` snap:

```
$ store-admin export snaps jq htop --channel=stable --arch=amd64 --arch=arm64 --export-dir .
Downloading jq revision 6 (latest/stable amd64)
  [####################################]  100%
Downloading jq revision 8 (latest/stable arm64)
  [####################################]  100%
Downloading htop revision 3417 (latest/stable amd64)
  [####################################]  100%          
Downloading htop revision 3425 (latest/stable arm64)
  [####################################]  100%          
Successfully exported snaps:
jq: jq-20221026T104628.tar.gz
htop: htop-20221026T104628.tar.gz
```

This produces a set of `tar.gz` files (one per snap name) that have to be moved
to the on-prem store host and imported there.

!!! Positive "":
    By default snaps are exported from the Global store, and then imported as
    such, meaning that any device connected to the on-prem store will be able to
    install them (if it's configured to use the default Global store).
    `store-admin export snaps` has a `--store` option allowing for authenticated
    export of snaps from private device-view IoT App Stores - after importing
    these, snaps will be accessible only to properly authenticated devices from
    the relevant brand.


#### Importing (pushing) snaps

Once the snap bundles are on the on-prem store host, they should be moved to the
`/var/snap/snap-store-proxy/common/snaps-to-push/` directory, from where they
can be imported.

Example of importing a `jq.tar.gz` snap bundle on the air-gapped proxy host:

```bash
sudo snap-store-proxy push-snap /var/snap/snap-store-proxy/common/snaps-to-push/jq-20200406T103511.tar.gz
```

The `jq` snap is now available for installation from this air-gapped Snap Store
Proxy. This means that `snap info jq` and `snap install jq` will succeed on a
connected client device.

### Essential snaps

Devices that connect to a store expect that snaps pre-installed on those devices
will be available in that store. Otherwise common operations like `snap refresh`
will fail. Air-gapped store operators should ensure that all necessary snaps are
imported. Snaps commonly pre-installed on devices may include but are not
limited to:

- `core`
- `core18`
- `core20`
- `core22`
- `snapd`

## Client Device Configuration

[Configuring client devices](devices.md) follows the same process as with an
online Snap Store Proxy.

## Limitations

Offline mode provides only a subset of the core functionality of the online
Snap Store Proxy or the SaaS Snap Store. Some of the missing features are:

* Searching for snaps

* Generic Device registration. Serial Vault can be used to register custom model
  devices.
