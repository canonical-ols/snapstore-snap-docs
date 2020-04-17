---
title: Air-gapped mode
table_of_contents: true
---

# Air-gapped mode

Snap Store Proxy can operate in an air-gapped (offline) mode, meaning it can be
deployed in networks that are disconnected from the internet.

!!! NOTE:
    The air-gapped mode is in a closed internal beta currently.

## Overview

Client devices connect to the air-gapped Snap Store Proxy. The proxy never
contacts the general Snap Store nor the internet in general.

Proxy operators side-load all necessary snaps into their air-gapped Snap Store
Proxy.

## Registration

Air-gapped Snap Store Proxy operators first have to register their offline proxy
on a **machine with internet access**:

```bash
sudo snap install snap-store-proxy --edge

sudo snap-proxy generate-keys

sudo snap-proxy config proxy.domain="$<domain-or-ip-of-the-air-gapped-proxy>"
```

Follow the [HTTPS setup guide](https.md) to ensure that your offline Snap Store
Proxy will be registered behind HTTPS scheme, meaning that any client device
that attempts to use it, will contact it via HTTPS.

On the same machine, register the air-gapped Snap Store Proxy:

```bash
# You'll be prompted to provide your SSO authentication and will
# be asked some survey questions about the intended proxy usage.
sudo snap-proxy register --offline --channel=edge --arch=amd64
```

The result of the above is a tarball `offline-snap-store.tar.gz` that is then
moved to the target host machine for the air-gapped Snap Store Proxy.

## Database setup

The target machine (the air-gapped Snap Store Proxy host) should have network
access to a [properly configured PostgreSQL database](install.md#database).

## Installation

You will need the `offline-snap-store.tar.gz` bundle from the registration step
to continue with installation.

!!! NOTE:
    The air-gapped mode is in a closed internal beta currently and installation
    is password protected.

The script below illustrates the installation process on the target air-gapped
machine. Please note that the following variables need to be set appropriately:

* `POSTGRESQL_CONN_STRING` - the connection string to a
  [properly set up PostgreSQL database](install.md#database)

* `SNAPSTORE_BETA_PASSWORD` - a closed beta password required for the
  installation of the air-gapped Snap Store Proxy

* `PROXY_ACCESS_PASSWORD` - password required for management of the air-gapped
  Snap Store Proxy over the network

```bash
#!/bin/bash

set -eu

# PostgreSQL connection string to the Snap Store Proxy database.
POSTGRESQL_CONN_STRING="${POSTGRESQL_CONN_STRING}"
# Closed beta password required for the airgap installation.
SNAPSTORE_BETA_PASSWORD="${SNAPSTORE_BETA_PASSWORD}"
# Management access password for the proxy.
PROXY_ACCESS_PASSWORD="${PROXY_ACCESS_PASSWORD}"

tar xvzf offline-snap-store.tar.gz
cd offline-snap-store
./install.sh

sudo snap-store-proxy config proxy.db.connection="$POSTGRESQL_CONN_STRING"

SNAPSTORE_BETA_PASSWORD="$SNAPSTORE_BETA_PASSWORD" sudo -E snap-store-proxy enable-airgap-mode --password $PROXY_ACCESS_PASSWORD

sudo snap-store-proxy status
```

## Side-loading snaps

Air-gapped Snap Store Proxy operators can fetch snaps from the official Snap
Store and import them into their air-gapped proxy. These will be the only snaps
(and their revisions) available for installation from the air-gapped proxy.

### Fetching snaps

Example of fetching the `jq` snap on a **machine with internet access**:

```bash
sudo snap-store-proxy fetch-snaps jq --channel=stable --architecture=amd64
```

This produces a `tar.gz` file that has to be moved to the air-gapped proxy and
imported there.

### Importing (pushing) snaps

Example of importing a `jq.tar.gz` snap bundle on the air-gapped proxy host:

```bash
sudo snap-store-proxy push-snap jq.tar.gz
```

The `jq` snap is now available for installation from this air-gapped Snap Store
Proxy. This means that `snap info jq` and `snap install jq` will succeed on a
connected client device.

## Client Device Configuration

Client devices only ever connect to the offline proxy. They do this without
sending any device authentication/authorization information to the proxy. A
client device that has already obtained a
[serial assertion](https://docs.ubuntu.com/core/en/reference/assertions/serial),
will not be able to use the air-gapped proxy, as the air-gapped proxy currently
is unable to authenticate its client devices offline.

[Configuring client devices](devices.md) follows the same process as with an
online Snap Store Proxy.

## Limitations

Air-gapped mode provides only a subset of the core functionality of the regular
Snap Store Proxy or the official Snap Store. Some of the missing features are:

* Searching for snaps

* Device registration and authorization
