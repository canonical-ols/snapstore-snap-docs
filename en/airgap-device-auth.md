---
title: Device Authenticated Air-gapped mode
table_of_contents: true
---

# Device Authenticated Air-gapped mode

[Brand Store](https://ubuntu.com/core/docs/store-overview) customers can use the
Snap Store Proxy in air-gapped mode to serve updates to their fleet of devices.

Operators can import their brand store snaps (including any essential and other
snaps included from the global store in their brand store) to their airgap Snap
Store Proxy.

Devices with valid serial assertions for models belonging to a specific brand
can authenticate to such proxy and get access to imported brand store snaps
which are not accessible to any other devices connecting to that proxy.

Follow the instructions below to setup your air-gapped proxy in a way that
allows for brand devices to be able access and update their brand store (and
brand store included) snaps.

!!! NOTE:
    The client devices have to be equipped with their serial assertions and the
    air-gapped proxy itself does not support device registration.

!!! NOTE:
    The client devices should only ever connect to their target air-gapped
    proxy, to ensure that the device session they obtain is signed with the
    air-gapped proxy unique secret key (`snap-store-proxy config
    proxy.device-auth.secret`). This unique key is generated when air-gapped
    mode is activated for a proxy, and it should be securely backed up.

### Fetching brand store snaps

To fetch non publicly available brand store snaps for a subsequent import to the
air-gapped proxy, the `fetch-snaps` command with its `--auth` and `--store`
options can be used. First a login file has to be obtained from an account with
a *Viewer* role for the brand store in question, using the `snapcraft` tool:

```bash
snapcraft export-login --acls package_access
```

Then this file has to be moved to a location accessible by the snap-store-proxy
snap, like `/var/snap/snap-store-proxy/common/`, and the snap can be fetched:

```bash
# On a machine with internet access and the proxy being in online mode:
sudo snap-store-proxy fetch-snaps <snap-name> \
    --channel=stable --architecture=amd64 \
    --auth <path-to-snapcraft-login-file> \
    --store <brand-store-id>
```

The above needs to be repeated for all snaps (both brand store and global store)
that are pre-installed on the airgap proxy client devices, as well as any snaps
and their dependencies those devices are expected to be able to install later.

To fetch publicly available global store snaps, the `--store` and `--auth`
options can be omitted.

### Fetching brand store metadata

To fetch brand store metadata needed for import to the air-gapped proxy, the
`fetch-brand-store-metadata` snap-store-proxy command can be used on a machine
with internet access. But first a login file has to be obtained from an account
with an *Admin* role for the brand store in question, using the `snapcraft`
tool:

```bash
snapcraft export-login --acls store_admin
```

Then this file has to be moved to a location accessible by the snap-store-proxy
snap, like `/var/snap/snap-store-proxy/common/`, and the brand store metadata
can be fetched:

```bash
sudo snap-store-proxy fetch-brand-store-metadata <brand-store-id> <path-to-snapcraft-login-file>
```

### Fetching brand account keys

Any [account
keys](https://ubuntu.com/core/docs/reference/assertions/account-key) used for
signing brand devices'
[models](https://ubuntu.com/core/docs/reference/assertions/model) and
[serials](https://ubuntu.com/core/docs/reference/assertions/serial) have to be
registered with the Snap Store using `snapcraft register-key` and then fetched
and imported to the air-gapped proxy those devices will connect to for the proxy
to be able to authenticate them.

To fetch those assertions, the snap-store-proxy `fetch-account-keys` can be used:

```bash
snap-store-proxy fetch-account-keys <brand-account-id> <key-id> <key-id> ...
```

So if `FQaqU5d8LtMU5L16h47S10R26eDqxZL7NNdJGSOryG6yTSWGeSGEpeFSQZOfH5Tr` key is
used for signing serials,
`tQUaubkyr7d0EshPal8oncc0Dj2WBsydl2I2B2O6jRa7Quxs_wUg0jUw3cNBK65G` is used for
signing models, and the brand account id is `my-brand`:

```bash
snap-store-proxy fetch-account-keys \
    my-brand \
    tQUaubkyr7d0EshPal8oncc0Dj2WBsydl2I2B2O6jRa7Quxs_wUg0jUw3cNBK65G \
    FQaqU5d8LtMU5L16h47S10R26eDqxZL7NNdJGSOryG6yTSWGeSGEpeFSQZOfH5Tr
```

### Pushing snaps

All the fetched snaps can be pushed to the air-gapped proxy using the regular
`push-snaps` command:

```bash
sudo snap-store-proxy push-snap <path-to-fetched-snap.tar.gz>
```

### Pushing brand store metadata

After all required snaps have been pushed (`snap-store-proxy list-pushed-snaps`
can be used to see the current status), the brand store metadata must be
imported to the air-gapped proxy using:

```bash
sudo snap-store-proxy push-brand-store-metadata <path-to-fetched-store-metadata.json>
```

### Pushing account keys

And lastly the fetched account keys need to be imported:

```bash
sudo snap-store-proxy push-account-keys <path-to-fetched-keys-file.assert>
```

### Status

`snap-store-proxy status` lists the imported stores and account keys and
`snap-store-proxy list-pushed-snaps` lists all imported snaps.

Running `snap info <snap-name>` from a device connected to the air-gapped proxy
can be used to view more details about the snap, like it's current channel map.


### Proxy config backup

Make sure to securely backup the snap-store-proxy configuration (including the
proxy.device-auth.secret used for signing/verifying the device sessions). The
config can be exported with:

```bash
sudo snap-store-proxy config > proxy-config-backup.txt
sudo snap-store-proxy config proxy.device-auth.secret > proxy.device-auth.secret.txt
sudo snap-store-proxy config proxy.auth.secret > proxy.auth.secret.txt
sudo snap-store-proxy config proxy.key.private > proxy.key.private.txt
sudo snap-store-proxy config proxy.tls.key > proxy.tls.key.txt
```

### Client Device Configuration

[Configuring client devices](devices.md) follows the same process as with an
online Snap Store Proxy.
