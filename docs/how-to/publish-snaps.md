# How to publish snaps to the Enterprise Store

```{warning}
This functionality requires a [Dedicated Snap Store](https://ubuntu.com/internet-of-things/appstore), also known as an IoT App Store.
```

To publishing snaps directly to an Enterprise Store, you need the Enterprise Store
to be configured with a Brand account, and for the snaps in question to be
registered to the same Brand account. Additionally, once registered, customers
need to **submit a support ticket** to request the modification of each snap's
snap-declaration to include a value for the `provenance` of the snap.

```{note}
Provenance can be an alphanumeric string that includes hyphens, eg. `acme-site-7`.
```

Additionally, the Dedicated Snap Store should also contain keys for signing
device [models](https://ubuntu.com/core/docs/reference/assertions/model) and
[serials](https://ubuntu.com/core/docs/reference/assertions/serial).

## Exporting store data

Relevant Dedicated Snap Store data must be exported to the Enterprise Store. This
is done using the `store-admin` snap.

On a snap compatible machine with internet access, export the desired store and
the relevant keys. For example, where `keyid1`, `keyid2`, and `keyid3` are
sha3-384 fingerprints of the respective registered keys:

```{terminal}
:user: user
:host: admin-box
:copy:
:input: store-admin export store --arch=amd64 --arch=arm64 --channel=stable --channel=edge --key=keyId1 --key=keyId2 --key=keyId3 myDeviceViewStoreID

Logging in as store admin...
Opening an authorization web page in your browser.
If it does not open, please open this URL:
 https://api.jujucharms.com/identity/login?did=idxyz

Downloading store metadata and assertion...
Downloading store admin account details and assertion...
Downloading snap declaration for my-registered-unbpublished-snap1...
Downloading account-key keyId1...
Downloading account-key keyId2...
Downloading account-key keyId3...
Downloading core revision 13250 (latest/stable amd64)
  [####################################]  100%          
Downloading core revision 13253 (latest/stable arm64)
  [####################################]  100% 
```

```{note}
You will need to authenticate using an account with **Admin** permissions for the store you are exporting.
```

Data will be exported to the `/home/<user>/snap/store-admin/common/export/` directory.

```{dropdown} Exported data
* SaaS stores' (*device view* store and its parent) metadata.
* Admin account data and a credentials used for signing and publisher operations.
* Registered public keys as account-key assertions for key IDs specified with the `--key` option.
```

```{warning}
Make sure to include the keys used for signing client device serial and model assertions, and the key that will be used for signing snap revision assertions for snaps published directly to the on-prem store. These keys have to be registered using `snapcraft register-key` command prior to the export.
```

## Import store data

Move the exported store bundle to the on-prem store machine and run the import command:

```{terminal}
:user: user
:host: onprem-box
:copy:
:input: sudo snap-proxy push-store --revision-authority-key-id keyid1 --revision-authority-key /var/snap/enterprise-store/common/snaps-to-push/keyid1.private.key /var/snap/enterprise-store/common/snaps-to-push/store-export-myDeviceViewStoreID.tar.gz


Uploaded snap and assertions for core revision 13250
Uploaded snap and assertions for core revision 13253
...
Pushing store your-brand-store-abc-main
Pushing store assertions
Pushing store your-brand-store-abc-devices
Pushing store assertions
Updating store allowlists 
Restarting services
Store admin account imported successfully.
```

````{note}
The key file specified with `--revision-authority-key` contains the **private key** corresponding to one of the public keys exported using the `store-admin export store` command. It can be exported from the machine that holds the brand account keys (this account should have been set up as part of initial Brand store onboarding process) using:

```{terminal}
:user: user
:host: host
:copy:
:input: gpg --homedir ~/.snap/gnupg --export-secret-keys --armor <key-name>`
```

Where `<key-name>` is the name as shown in the `snapcraft list-keys` output. A matching `--revision-authority-key-id` has to be specified as well (also available in the `snapcraft list-keys` output).

It is not necessary to specify `--revision-authority-key` nor `--revision-authority-key-id` during subsequent synchronisation (push-store invocations).
````

## Configure Enterprise Store provenance

Configure the snap revision provenance for this on-prem store (the value for this setting must be the one chosen earlier). For example, using `acme-site-7`:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo enterprise-store config internal.airgap.store.provenance-allowlist=acme-site-7
```

## Build and publish with Snapcraft

Snapcraft is used to build revision authority delegated snaps, and to publish them to the on-prem store.


```{terminal}
:user: user
:host: host
:copy:
:input: sudo snap install snapcraft --classic
```

Configure Snapcraft for your on-prem store using the data exported from the data provided with `store-admin export store`:

```{terminal}
:user: user
:host: admin-box
:input: export SNAPCRAFT_ADMIN_MACAROON=$(cat /home/<user>/snap/store-admin/common/export/storeID.macaroon)

:input: export SNAPCRAFT_STORE_AUTH=onprem
:input: export STORE_DASHBOARD_URL="https://example.store/publishergw"
:input: export STORE_UPLOAD_URL="https://example.store"
```

Next, login to the on-prem store as the publisher and export the credentials to a file:


```{terminal}
:user: user
:host: admin-box
:input: snapcraft export-login <publisher_account>
```

Set the credential produced by `export-login` as `SNAPCRAFT_STORE_CREDENTIALS` environment variable:

```{terminal}
:user: user
:host: admin-box
:input: export SNAPCRAFT_STORE_CREDENTIALS="$(cat <publisher_account>)"
```

You can now `snapcraft upload` and `snapcraft release` to the on-prem store.

```{note}
Commands supported by on-prem stores are:

* `snapcraft status <snap-name>`
* `snapcraft list-revisions <snap-name>`
* `snapcraft upload <snap-file>`
* `snapcraft release [options] <snap-name> <revision> <channels>`
* `snapcraft close [options] <snap-name> <channel>`
```

```{warning}
There is no support for custom tracks or branches, and there is no support for progressive releases.
```