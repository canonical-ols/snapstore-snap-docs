# Upgrade from Snap Store Proxy to Enterprise Store

[Snap Store Proxy](https://snapcraft.io/snap-store-proxy) has been renamed to [Enterprise Store](https://snapcraft.io/enterprise-store). The Snap Store Proxy snap will be maintained for the time being, but it is recommended to upgrade to the Enterprise Store snap.

On the system with Snap Store Proxy installed:

1. Install the Enterprise Store snap:

```
snap install enterprise-store
```

2. Export your existing configuration with:

   

```
sudo snap-store-proxy config --export-yaml > proxy-config-backup.txt;
sudo snap-store-proxy config proxy.device-auth.secret > proxy.device-auth.secret.txt;
sudo snap-store-proxy config proxy.auth.secret > proxy.auth.secret.txt;
sudo snap-store-proxy config proxy.key.private > proxy.key.private.txt;
sudo snap-store-proxy config proxy.tls.key > proxy.tls.key.txt
```

3. Import your configuration to the Enterprise Store with:

```
sudo enterprise-store config --import-yaml proxy-config-backup.txt;
sudo enterprise-store config proxy.device-auth.secret=$(cat proxy.device-auth.secret.txt);
sudo enterprise-store config proxy.auth.secret=$(cat proxy.auth.secret.txt);
sudo enterprise-store config proxy.key.private=$(cat proxy.key.private.txt);
sudo enterprise-store config proxy.tls.key=$(cat proxy.tls.key.txt)
```

4. Move files from the Snap Store Proxy’s scanned directory to the Enterprise Store’s scanned directory:

```
sudo mv /var/snap/snap-store-proxy/common/snapstorage-local/scanned/* /var/snap/enterprise-store/common/snapstorage-local/scanned/
```

5. Remove the Snap Store Proxy snap:

```
sudo snap remove snap-store-proxy
```

