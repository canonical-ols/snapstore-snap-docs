# How to import Dedicated Snap Store snaps

```{warning}
This functionality requires a [Dedicated Snap Store](https://ubuntu.com/internet-of-things/appstore), also known as an IoT App Store.
```

Export snaps from your Dedicted Snap Store using the `store-admin` snap:

```{terminal}
:user: user
:host: admin-box
:input: store-admin export store --arch=amd64 --arch=arm64 --channel=stable --channel=edge StoreID
```

This will export any snaps available in the store, with their channel maps, metadata,
and assertions.

Once you move the exported store bunclde to your on-prem store, you can run the import command:

```{terminal}
:user: user
:host: onprem-box
:input: sudo enterprise-store push-store /var/snap/enterprise-store/common/snaps-to-push/store-export-StoreID.tar.gz

Uploaded snap and assertions for core revision 13250
Uploaded snap and assertions for core revision 13253
...
```