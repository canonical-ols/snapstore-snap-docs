# Synchronise with a Dedicated Snap Store

```{warning}
This functionality requires a [Dedicated Snap Store](https://ubuntu.com/internet-of-things/appstore), also known as an IoT App Store.
```

Dedicated Snap Store credentials and snaps can be exported using the `store-admin` snap.

```{terminal}
:user: user
:host: admin-box
:input: store-admin export store --help

Usage: store-admin export store [OPTIONS] STORE_ID

  Export your IoT App Store data for import to the offline store.

  STORE_ID: Store ID of a "device view" app store.

  See the `export token` subcommand for non-interactive authentication.

Options:
  --no-snaps      Do not export snap revisions of snaps available in the
                  exported store. Metadata about snaps that are not released
                  will still be exported.
  --channel TEXT  Channels to export snaps available in the store from. (This
                  option can be specified multiple times)  [default: stable]
  --arch TEXT     Architectures of exported snaps available in the exported
                  store. (This option can be specified multiple times)
                  [default: amd64]
  --key TEXT      IDs of registered snapcraft signing keys to export. Make
                  sure to export relevant snap revision signing key, device
                  model and serial signing keys. (This option can be specified
                  multiple times)
  -h, --help      Show this message and exit.
```

For example, to export snaps contained in a [Device View](https://documentation.ubuntu.com/dedicated-snap-store/explanation/base-stores-and-device-view-stores/#device-view-stores)
store:

```{terminal}
:user: user
:host: admin-box
:input: store-admin export store --arch=amd64 --arch=arm64 --channel=stable --channel=edge StoreID
```

This will export any snaps available in the store, with their channel maps, metadata,
and assertions.

Once you move the exported store bundle to your store, you can run the import command:

```{terminal}
:user: user
:host: enterprise-store-host
:input: sudo enterprise-store push-store /var/snap/enterprise-store/common/snaps-to-push/store-export-StoreID.tar.gz

Uploaded snap and assertions for core revision 13250
Uploaded snap and assertions for core revision 13253
...
```