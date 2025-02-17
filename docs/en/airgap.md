---
title: Operate offline
table_of_contents: true
---

# Offline store (air-gapped mode)

By default, the Enterprise Store operates in online mode. It acts as a smart
proxy to the general SaaS Snap Store.

Enterprise Store can operate in offline mode and act as a local Snap Store
(on-prem store), meaning it can be deployed in networks that are disconnected
from the internet.

The intended use case for this mode are network restricted environments where no
outside traffic is allowed or possible.

## Overview

Client devices connect to the offline store. The local store doesn't directly
contact the general SaaS Snap Store nor the internet.

Proxy operators side-load all necessary snaps and other metadata into their
local store by exporting them from the SaaS store first and then importing into
their offline store.

### Brand Store support

[Brand Store](https://ubuntu.com/core/docs/store-overview)
(also known as [IoT App Store](https://ubuntu.com/internet-of-things/appstore))
customers can use the Enterprise Store in offline mode to securely serve updates
to their fleet of devices.

Operators can import their brand store snaps (including any essential and other
snaps included from the global store in their brand store) to their on-prem
store.

Devices with valid serial assertions for models belonging to a specific brand
can authenticate to such on-prem store and get access to imported brand store
snaps which are not accessible to any other devices connecting to that on-prem
store.

```{note}
Client devices have to be equipped with their
[serial assertions](devices.md#obtaining-serial-assertions).
```

## Installation

If the target host has internet access at the time of installation, then the
regular [installation](install.md) and [registration](register.md) can be used
followed by airgap mode activation:

```bash
sudo snap-proxy enable-airgap-mode
```

```{note}
Even though it's possible to enable airgap mode for an online proxy, it's
only advised to do so during the installation phase when no devices are yet
[connected](devices.md) to the proxy. Deactivating and activating airgap
mode while it's already serving clients will have undesirable and not
clearly defined consequences for the devices that were connected to it
before the mode switch as well as for the snap-store-proxy instance itself.
```

### Offline installation

To deploy an offline store (Enterprise Store in air-gapped mode) to a machine
without internet access it's possible to register it using a separate machine
first and install the resulting package on the target machine.

Air-gapped Enterprise Store operators first have to register their offline proxy
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

```{warning}
    Full value of the target location, eg `https://snaps.internal`, will be encoded
    in an assertion file used for instructing client devices to connect to this
    store. It's important to decide if http or https will be used and what the host
    name will be at the point of registration.
```

The result of the above is a tarball `offline-snap-store.tar.gz` that is then
moved to the target host machine for the offline store for installation.

The target machine (the air-gapped Enterprise Store host) should have network
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

# PostgreSQL connection string to the Enterprise Store database.
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

## Brand store metadata import

```{warning}
    This section is relevant for brand store customers wanting to host their
    brand store snaps offline and can be skipped if the offline store only has
    to support Global store client devices (eg. generic devices).
```

On-prem stores need various data (assertions, snap binaries and metadata,
account information) - produced by the upstream Snap Store - to function. This
data has to be exported from the SaaS IoT App store and imported into the
on-prem store at least once.

Any
[account keys](https://ubuntu.com/core/docs/reference/assertions/account-key)
used for signing brand devices'
[models](https://ubuntu.com/core/docs/reference/assertions/model) and
[serials](https://ubuntu.com/core/docs/reference/assertions/serial) have to be
registered with the SaaS Snap Store using `snapcraft register-key` (by the brand
account) prior to the export in order for the on-prem store to be able to
authenticate brand store devices.

The store export and import steps can be repeated to "synchronise" the data
and/or snaps from the SaaS store as needed.

### Brand store export

To export brand store metadata needed for import to the on-prem store, the
`store-admin export store` command can be used on a machine with internet
access. Authentication using an account with *Admin* role for the brand store in
question is required. Example:

```
$ store-admin export store \
    --arch=amd64 --arch=arm64 \
    --channel=stable --channel=edge \
    --key=keyId1 --key=keyId2 \
    myDeviceViewStoreID

Logging in as store admin...
Opening an authorization web page in your browser.
If it does not open, please open this URL:
 https://api.jujucharms.com/identity/login?did=idxyz

Downloading store metadata and assertion...
Downloading store admin account details and assertion...
Downloading snap declaration for my-registered-unbpublished-snap1...
Downloading account-key keyId1...
Downloading account-key keyId2...
Downloading core revision 13250 (latest/stable amd64)
  [####################################]  100%
Downloading core revision 13253 (latest/stable arm64)
  [####################################]  100%

...

Creating the export archive...
Store data exported to: /home/ubuntu/snap/store-admin/common/export/store-export-myDeviceViewStoreID-20220527T082652.tar.gz
```

The above will export the following data:

- SaaS IoT App Stores' (device view store and its parent) metadata,

- Registered public keys in form of account-key assertions for key IDs specified
  with the `--key` option. Make sure to include the keys used for signing client
  device serial and model assertions. These keys have to be registered using
  `snapcraft register-key` command prior to the export, by the brand account.

- Snaps available in the SaaS stores, with their metadata and assertions.
  Currently published revisions of the snaps will be exported according to the
  specified architectures and channels: `--arch`, `--channel`. The `--no-snaps`
  option can be used to skip the export of any snap revisions
  (`store-admin export snaps` can be used to export snaps in a more granular
  fashion).


### Brand store import

The exported `store-export-*.tar.gz` file can be imported on the target on-prem host using the `snap-proxy push-store` command. Example:

```
sudo snap-proxy push-store \
    /var/snap/snap-store-proxy/common/snaps-to-push/store-export-myDeviceViewStoreID.tar.gz

```

## Side-loading snaps

It's possible to export snaps from the upstream Snap Store and import them into
their on-prem store. These will be the only snaps (and their revisions)
available for installation from the on-prem store.

### Exporting snaps

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

```{note}
By default snaps are exported from the Global store, and then imported as
such, meaning that any device connected to the on-prem store will be able to
install them (if it's configured to use the default Global store).
`store-admin export snaps` has a `--store` option allowing for authenticated
export of snaps from private device-view IoT App Stores - after importing
these, snaps will be accessible only to properly authenticated devices from
the relevant brand.
```

### Importing (pushing) snaps

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


## Status

```
snap-store-proxy status
```
lists the imported stores and account keys and

```
snap-store-proxy list-pushed-snaps
```
lists all imported snaps.

Running `snap info <snap-name>` from a device connected to the on-prem store can
be used to view more details about the snap, like its current channel map.


## Client Device Configuration

[Configuring client devices](devices.md) follows the same process as with an
online Enterprise Store.


## Offline Upgrades

To upgrade snap-store-proxy on an offline machine, first download the snap and
its assertions on a machine with internet access, e.g.:


```bash
snap download snap-store-proxy --channel=latest/stable
```

Same can be done for its base snap `core22` and for the `snapd` snap itself.

Then move the files over to the offline snap-store-proxy machine and:

```bash
sudo snap ack snap-store-proxy_<revision>.assert
sudo snap install snap-store-proxy_<revision>.snap
```

And use analogous process to upgrade the base and `snapd` snaps.


## Configuration backup

Make sure to securely backup the snap-store-proxy configuration (including the
`proxy.device-auth.secret` used for signing/verifying the device sessions). The
configuration can be exported with:

```bash
sudo snap-store-proxy config > proxy-config-backup.txt
sudo snap-store-proxy config proxy.device-auth.secret > proxy.device-auth.secret.txt
sudo snap-store-proxy config proxy.auth.secret > proxy.auth.secret.txt
sudo snap-store-proxy config proxy.key.private > proxy.key.private.txt
sudo snap-store-proxy config proxy.tls.key > proxy.tls.key.txt
```

## Limitations

Offline mode provides only a subset of the core functionality of the online
Enterprise Store or the SaaS Snap Store. Some of the missing features are:

* Searching for snaps

* Generic Device registration. Serial Vault can be used to register custom model
  devices.
