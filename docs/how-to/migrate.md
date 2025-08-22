# Migrate from Snap Store Proxy to Enterprise Store

[Snap Store Proxy](https://snapcraft.io/snap-store-proxy) has been renamed to [Enterprise Store](https://snapcraft.io/enterprise-store). The Snap Store Proxy snap will be maintained for the time being, but it is recommended to upgrade to the Enterprise Store snap.

On the system with Snap Store Proxy installed:

1. Install the Enterprise Store snap.

In an online context, run:

```
snap install enterprise-store
```

In an offline context, first download the snap and its assertions on
a machine with internet access, e.g.:
```bash
snap download enterprise-store --channel=latest/stable
```

Then move the files over to the offline enterprise-store machine and:

```bash
sudo snap ack enterprise-store_<revision>.assert
sudo snap install enterprise-store_<revision>.snap
```

2. Copy over important files from the Snap Store Proxy’s common
directory to the Enterprise Store’s common directory:

```
sudo cp -r /var/snap/snap-store-proxy/common/snapstorage-local /var/snap/enterprise-store/common/snapstorage-local
sudo cp -r /var/snap/snap-store-proxy/common/nginx/airgap /var/snap/enterprise-store/common/nginx/airgap
sudo cp -r /var/snap/snap-store-proxy/common/snaps-to-push /var/snap/enterprise-store/common/snaps-to-push
sudo cp -r /var/snap/snap-store-proxy/common/charms-to-push /var/snap/enterprise-store/common/charms-to-push
```

3. Export the existing configuration with:

```
sudo snap-store-proxy config --export-yaml | cat > store-config.yaml
```

```{warning}
The YAML file should be stored securely, since it includes sensitive data like secrets.
```

```{note}
If the `--export-yaml` option is unavailable, upgrade to the latest
version of the `snap-store-proxy` snap, which will contain the
`--export-yaml` option.
```

4. Import the configuration to the Enterprise Store:

```
cat store-config.yaml | sudo enterprise-store config --import-yaml
```

This command may fail, since the Enterprise Store service ports
conflict with the existing Snap Store Proxy service ports. This should
be expected. An example output of this is:

```bash
$ cat store-config.yaml | sudo enterprise-store config --import-yaml
Configured database for packagereview role.
Configured database for packagereview-celery role.
Configured database for snaprevs role.
Configured database for snapauth role.
Configured database for snapident role.
Configured database for snapassert role.
Configured database for updown role.
Configured database for snapmodels role.
error: Command '['snapctl', 'restart', '--reload', 'enterprise-store.nginx', 'enterprise-store.snapmodels', 'enterprise-store.memcached', 'enterprise-store.storeadmingw', 'enterprise-store.packagereview', 'enterprise-store.snapassert', 'enterprise-store.snapauth', 'enterprise-store.snapproxy', 'enterprise-store.snapstorage', 'enterprise-store.packagereview-worker', 'enterprise-store.snapident', 'enterprise-store.snaprevs', 'enterprise-store.snapdevicegw', 'enterprise-store.publishergw']' returned non-zero exit status 1.
```

5. Use the Enterprise Store's services instead of the Snap Store Proxy's.

Disable the Snap Store Proxy snap (this may cause temporary downtime):

```
sudo snap disable snap-store-proxy
```

Start the Enterprise Store services:

```
sudo snap start enterprise-store
```

The Enterprise Store services should now be able to bind to the
appropriate ports. Check the status:

```
enterprise-store status
```

````{note}
If anything goes wrong during the downtime after disabling the
snap-store-proxy snap, revert to the initial state by running:

  ```
  sudo snap stop enterprise-store
  sudo snap enable snap-store-proxy
  sudo snap start snap-store-proxy
  sudo snap disable enterprise-store
  ```

  Check the status:

  ```
  snap-store-proxy status
  ```
````

6. Verify that functionality for existing devices/clients still works.

7. Remove the Snap Store Proxy snap:

```
sudo snap remove snap-store-proxy
```

