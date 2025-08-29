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
sudo cp -r /var/snap/snap-store-proxy/common /var/snap/enterprise-store/
```

3. Verify that the files were copied over:

```
# Outputs should look similar
ls -R /var/snap/snap-store-proxy/common
ls -R /var/snap/enterprise-store/common
```

4. Export the existing configuration with:

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

5. Import the configuration to the Enterprise Store:

```
cat store-config.yaml | sudo enterprise-store config --import-yaml
```

**This command will fail** if Snap Store Proxy is running, as the Enterprise
Store service ports conflict with the existing Snap Store Proxy service ports.
This is expected. An example output of this is:

```{terminal}
:input: cat store-config.yaml | sudo enterprise-store config --import-yaml
:copy:

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

6. Set the Enterprise Store's
`internal.snapstorage.local-origin-secret` secret configuration value
to the equivalent value from the Snap Store Proxy's.

Check if it was set with:

```
sudo snap get snap-store-proxy internal.snapstorage.local-origin-secret
```

If the option was set (no error with the command above), also set the
option in the Enterprise Store:

```
sudo enterprise-store config internal.snapstorage.local-origin-secret="$(sudo snap get snap-store-proxy internal.snapstorage.local-origin-secret)"
```

**This command will fail** with an expected output similar to:

```{terminal}
:input: sudo enterprise-store config internal.snapstorage.local-origin-secret="$(sudo snap get snap-store-proxy internal.snapstorage.local-origin-secret)"
:copy:

error: Command '['snapctl', 'restart', '--reload', 'enterprise-store.nginx', 'enterprise-store.snapmodels', 'enterprise-store.memcached', 'enterprise-store.storeadmingw', 'enterprise-store.packagereview', 'enterprise-store.snapassert', 'enterprise-store.snapauth', 'enterprise-store.snapproxy', 'enterprise-store.snapstorage', 'enterprise-store.packagereview-worker', 'enterprise-store.snapident', 'enterprise-store.snaprevs', 'enterprise-store.snapdevicegw', 'enterprise-store.publishergw']' returned non-zero exit status 1.
```

7. Set the Enterprise Store's
`internal.airgap.gateway-hash` configuration value
to the equivalent value from the Snap Store Proxy's.

Check if it was set with:

```
sudo snap get snap-store-proxy internal.airgap.gateway-hash
```

If the option was set (no error with the command above), also set the
option in the Enterprise Store:

```
sudo enterprise-store config internal.airgap.gateway-hash="$(sudo snap get snap-store-proxy internal.airgap.gateway-hash)"
```

**This command will fail** with an expected output similar to:

```{terminal}
:input: sudo enterprise-store config internal.airgap.gateway-hash="$(sudo snap get snap-store-proxy internal.airgap.gateway-hash)"
:copy:

error: Command '['snapctl', 'restart', '--reload', 'enterprise-store.nginx', 'enterprise-store.snapmodels', 'enterprise-store.memcached', 'enterprise-store.storeadmingw', 'enterprise-store.packagereview', 'enterprise-store.snapassert', 'enterprise-store.snapauth', 'enterprise-store.snapproxy', 'enterprise-store.snapstorage', 'enterprise-store.packagereview-worker', 'enterprise-store.snapident', 'enterprise-store.snaprevs', 'enterprise-store.snapdevicegw', 'enterprise-store.publishergw']' returned non-zero exit status 1.
```

8. Replace the Snap Store Proxy's services with the configured Enterprise Store.

Disable the Snap Store Proxy snap (this may cause temporary downtime):

```
sudo snap disable snap-store-proxy
```

Start the Enterprise Store services:

```
sudo snap start enterprise-store
```

Check the status:

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

9. Make a backup of the `snapstorage.package_store` table in the
PostgreSQL database, to use in case the next step goes wrong.

10. Connect to the PostgreSQL database and update the `bucket`
locations in the snapstorage database to use the `enterprise-store`
for the location, instead of `snap-store-proxy`.

For example, given the record:

```
-[ RECORD 1 ]+------------------------------------------------------------
id           | 1
object_uuid  | b124b223-6841-44cc-8a74-5cf4f8905989
path         | LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap
bucket       | /var/snap/snap-store-proxy/common/snapstorage-local/scanned
content_type | application/octet-stream
object_type  | snap
object_size  | 7897088
mark_deleted | f
when_created | 2025-08-29 05:25:40.236165
```

the new record should look like:

```
-[ RECORD 1 ]+------------------------------------------------------------
id           | 1
object_uuid  | b124b223-6841-44cc-8a74-5cf4f8905989
path         | LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap
bucket       | /var/snap/enterprise-store/common/snapstorage-local/scanned
content_type | application/octet-stream
object_type  | snap
object_size  | 7897088
mark_deleted | f
when_created | 2025-08-29 05:25:40.236165
```

The following SQL transaction should yield the desired outcome:

```sql
BEGIN;
-- Consider double-checking the state before and after the UPDATE
-- SELECT * from snapstorage.package_store;
UPDATE snapstorage.package_store SET bucket = regexp_replace(bucket, '\/var\/snap\/(snap-store-proxy)', '/var/snap/enterprise-store', 'g');
-- SELECT * from snapstorage.package_store;
COMMIT;
```

11. Verify that functionality for existing devices/clients still works.

If testing snap installs, keep in mind that `snapd` may have cached
previously downloaded snaps at `/var/lib/snapd/cache/`. Additionally,
the Enterprise Store may have cached snap downloads too. It may be
more suitable to clear the Enterprise Store cache and test directly
against the API:

```
sudo find /var/snap/enterprise-store/common/nginx/cache -maxdepth 1 -type f -delete
curl --fail 'https://my-store.test/api/v1/snaps/download/LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap' -o 'LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap'
```

12. Remove the Snap Store Proxy snap:

```
sudo snap remove snap-store-proxy
```
