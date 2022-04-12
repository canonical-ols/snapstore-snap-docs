---
title: Air-gapped mode (beta)
table_of_contents: true
---

# Air-gapped mode (beta)

Snap Store Proxy can operate in an air-gapped (offline) mode, meaning it can be
deployed in networks that are disconnected from the internet.

The intended use case for this mode are network restricted environments where no
outside traffic is allowed or possible.

## Overview

Client devices connect to the air-gapped Snap Store Proxy. The proxy never
contacts the general Snap Store nor the internet in general.

Proxy operators side-load all necessary snaps into their air-gapped Snap Store
Proxy.

## Installation

If the target host has internet access at the time of installation, then the
regular [installation](install.md) and [registration](register.md) can be used
followed by airgap mode activation:

```bash
sudo snap-proxy enable-airgap-mode
```

!!! NOTE:
    Even though it's possible to enable airgap mode for an online proxy, it's
    only advised to do so during the installation phase when no devices are yet
    connected to the proxy. Deactivating and activating airgap mode while it's
    already serving clients will have undesirable and not clearly defined
    consequences.

### Offline installation

To deploy an air-gapped Snap Store Proxy to a machine without internet access
it's possible to register it using a separate machine first and install the
resulting package on the target machine.

Air-gapped Snap Store Proxy operators first have to register their offline proxy
on a **machine with internet access**:

```bash
sudo snap install snap-store-proxy

sudo snap-proxy config proxy.domain="$<domain-or-ip-of-the-air-gapped-proxy>"
```

On the same machine, register the air-gapped Snap Store Proxy:

```bash
# You'll be prompted to provide your SSO authentication and will
# be asked some survey questions about the intended proxy usage.
sudo snap-proxy register --offline --channel=edge --arch=amd64
```

Add the `--https` option to the above `register` command if client devices are
expected to use HTTPS to connect to the proxy and follow the [HTTPS
setup](https.md) before continuing.

The result of the above is a tarball `offline-snap-store.tar.gz` that is then
moved to the target host machine for the air-gapped Snap Store Proxy.

The target machine (the air-gapped Snap Store Proxy host) should have network
access to a [properly configured PostgreSQL database](install.md#database).

You will need the `offline-snap-store.tar.gz` bundle from the registration step
to continue with installation.

The script below illustrates the installation process on the target air-gapped
machine. Please note that the following variables need to be set appropriately:

* `POSTGRESQL_CONN_STRING` - the connection string to a
  [properly set up PostgreSQL database](install.md#database)

* `PROXY_ACCESS_PASSWORD` - password required for management of the air-gapped
  Snap Store Proxy over the network

```bash
#!/bin/bash

set -eu

# PostgreSQL connection string to the Snap Store Proxy database.
POSTGRESQL_CONN_STRING="${POSTGRESQL_CONN_STRING}"
# Management access password for the proxy.
PROXY_ACCESS_PASSWORD="${PROXY_ACCESS_PASSWORD}"

tar xvzf offline-snap-store.tar.gz
cd offline-snap-store
sudo ./install.sh

sudo snap-store-proxy config proxy.db.connection="$POSTGRESQL_CONN_STRING"

sudo snap-store-proxy enable-airgap-mode --password $PROXY_ACCESS_PASSWORD

sudo snap-store-proxy status
```


## Usage

### Side-loading snaps

Air-gapped Snap Store Proxy operators can fetch snaps from the upstream Snap
Store and import them into their air-gapped proxy. These will be the only snaps
(and their revisions) available for installation from the air-gapped proxy.

#### Fetching snaps

Example of fetching the `jq` snap on a **machine with internet access**:

```bash
sudo snap-store-proxy fetch-snaps jq --channel=stable --architecture=amd64
```

This produces a `tar.gz` file that has to be moved to the air-gapped proxy and
imported there.

#### Importing (pushing) snaps

Once the snap bundles are on the airgap host, they should be moved to the
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
- `snapd`

## Client Device Configuration

[Configuring client devices](devices.md) follows the same process as with an
online Snap Store Proxy.

## Limitations

Air-gapped mode provides only a subset of the core functionality of the regular
Snap Store Proxy or the official Snap Store. Some of the missing features are:

* Searching for snaps

* Device registration
