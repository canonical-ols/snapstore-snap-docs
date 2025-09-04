# Enable High-Availability (HA)
By default, the Enterprise Store does not use a High Availability
configuration; if the machine with the Enterprise Store snap goes down,
then any requests made to it will fail.

Enterprise Store operators can opt to use a HA configuration, which
allows for multiple machines ("units") with the Enterprise Store snap
to be used for serving client requests. In this scenario, if one unit
goes down, then requests can be routed to another live unit.

## Overview
Below is a diagram of an example HA network topology:

![image info](../media/ha-overview.png)

At a high-level, the recommended approach for setting up HA is:

1. Fully configure a single Enterprise Store (ES) unit, including
relevant HA config options
2. Set up and configure at least one reverse proxy, using the
Enterprise Store unit as a backend server
3. Point devices/clients to the reverse proxy(s), verifying that
requests are working as intended
4. Create another ES unit, cloning over the relevant configuration
and files from the initial unit
5. Add the new unit as a backend/server to the reverse proxy(s)
6. Repeat steps 3-5 for the amount of units desired

## Configure the initial unit
Follow the documentation for [installation](install.md),
[registration](register.md) and/or [setting up an offline
store](airgap.md) depending on your use-case. These already assume the
use of a single unit, and a new Enterprise Store being set up. However,
there are some deviations to some of the steps in a HA setup.

If you already have an existing, non-HA Enterprise Store
with a single unit, refer to the [Existing Enterprise
Store](#existing-enterprise-store) section.

### TLS Termination
In HA setups, it is common to terminate the TLS connection at the
reverse proxy, with traffic to the backend units using unencrypted
HTTP, and devices/clients still communicating on a HTTPS connection. If
this is your desired network topology, then there is no need to
follow the HTTPS certificate setup for the ES unit outlined in
[Enhance Enterprise Store’s security](security.md), since HTTPS
will be configured on the reverse proxy(s) instead. Note that it is
important to indicate whether the Store expects client devices to
use HTTP or HTTPS traffic in the assertion via the appropriate
registration commands. For example, to set up a HTTPS Store, you
should specify:

    sudo enterprise-store register --https

or:

    store-admin register --offline "https://my-store.test"

to ensure that the correct protocol is encoded in the store assertion
used by client devices.

### Pin the snap

It is recommended to pin the enterprise-store snap on the
unit to to prevent automatic updates:

    sudo snap refresh --hold enterprise-store

```{note}
Issues may be encountered if running multiple enterprise-store versions
in the same HA cluster.
```

### Connect to PostgreSQL
See the [installation](install.md) guide for setting up and connecting
to a PostgreSQL server. To the connect to database, set the connecting
string:

    sudo enterprise-store config proxy.db.connection="postgresql://snapproxy-user@pghost.test:5432/snapproxy-db"

### Use a HA memcached or replace usage with PostgreSQL
By default, a single-unit Enterprise Store makes use of a local
memcached instance for storing time-bound data like nonces. For HA,
we need to either use PostgreSQL as the data store for the time-bound
data, or point the units to a separate, dedicated memcached cluster.

#### Use PostgreSQL
To use PostgreSQL instead of memcached, run:

    sudo enterprise-store config proxy.use-postgres-over-memcached="true"

```{warning}
The above option currently does not currently support the
[On-Prem Model Service](on-prem-model-service.md).
```

#### Use Memcached
To use memcached instance(s), set the connection strings with:

    # For a single instance
    sudo enterprise-store config proxy.memcached.connection='["memcached-1.test"]'
    # For multiple instances
    sudo enterprise-store config proxy.memcached.connection='["memcached-1.test","memcached-2.test"]'

The Enterprise Store uses `pymemcache` to distribute
data across a memcached cluster. See the [pymemcache
documentation](https://pymemcache.readthedocs.io/en/latest/getting_started.html#using-a-memcached-cluster)
for details on how the distribution works.

### Connect to S3 (offline store)
For an offline Enterprise Store, the unit must be configured to use
S3 as a blob storage backend.  The configuration options for S3 start
with `proxy.storage.s3`.

You will need to set the following options:

    # S3 server URL. Must be HTTP or HTTPS
    sudo enterprise-store config proxy.storage.s3.server-url="https://s3-server.test:9000"

    # S3 access key ID. For MinIO deployments, this is the username.
    sudo enterprise-store config proxy.storage.s3.access-key-id="admin"

    # S3 secret access key. For MinIO deployments, this is the password.
    sudo enterprise-store config proxy.storage.s3.secret-access-key="password"

    # S3 region. Leave as the default "us-east-1" if unsure
    sudo enterprise-store config proxy.storage.s3.region="us-east-1"

    # Whether to use path-style addressing for S3. The default is "true".
    sudo enterprise-store config proxy.storage.s3.use-path-style="true"

    # Name of the unscanned bucket, used for storing unscanned packages.
    # The default name is "unscanned-production". If it does not exist
    # on the server, it will be automatically created once the switch
    # is made to the S3 backend. It is advisable to check if the default
    # bucket name is already in use.
    sudo enterprise-store config proxy.storage.s3.unscanned-container-name="unscanned-production"

    # Name of the scanned bucket, used for storing scanned packages.
    # The default name is "scanned-production". If it does not exist on
    # the server, it will be automatically created once the switch is
    # made to the S3 backend. It is advisable to check if the default
    # bucket name is already in use.
    sudo enterprise-store config proxy.storage.s3.scanned-container-name="scanned-production"

When using a HTTPS connection to the S3 bucket, you will also need
to configure the unit to be able to verify the certificate from the
S3 server. To add a certificate on the unit, run:

    sudo cp s3-certificate.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    sudo systemctl restart snapd

Finally, switch to using S3 as the storage backend with:

    sudo enterprise-store config proxy.storage.backend="s3"

Verify that it works by running:

    enterprise-store status

There should be no failing services, especially
`snapstorage`. Additionally, you can verify that the relevant buckets
have been automatically created in the S3 server.

### Make the unit reverse proxy aware
Enterprise Store operators are expected to properly configure the
reverse proxy(s) to set the `X-Forwarded-Proto` header (see the next
section below for more info).

To make the backend unit trust this header, run:

    sudo enterprise-store config proxy.trust-forwarded-proto="true"

```{warning}
The unit should not be directly exposed to traffic from
devices/clients when this is enabled; the traffic must come from
the reverse proxy(s), and the header should be set appropriately.
```

## Configure the reverse proxy(s)
Reverse proxies like HAProxy or NGINX are situated between clients
and the backend Enterprise Store units. They need to be configured
correctly to interact with the backend units.

Reverse proxies must set the `X-Forwarded-Proto` HTTP
header appropriately depending the protocol used by the client
(`http`/`https`). Unsupported protocols should be denied. For example,
if you don't want to handle unencrypted HTTP traffic with clients,
then the reverse proxy should deny the request (or upgrade the
connection to HTTPS). Clients should not be able to directly set
the `X-Forwarded-Proto` header in their requests; only the reverse
proxy should.

Reverse proxies should also specify the relevant backend units in
the configuration.

An example portion of a HAProxy configuration might look like:
```
frontend my_frontend
  mode http
  # Use HTTPS
  bind *:443 ssl crt /etc/ssl/private/reverse-proxy.pem
  # Set the X-Forwarded-Proto header appropriately
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  # Uncomment and use section below if using HTTP instead
  # bind *:80
  # http-request add-header X-Forwarded-Proto http if !{ ssl_fc }
  default_backend web_servers

backend web_servers
  mode http
  balance roundrobin
  # Add health checks to units
  option httpchk HEAD /_status/check
  server s1 unit-ip-1.test:80 check
```

Don't forget to restart the reverse proxy to pick up the config.

## Point devices to the reverse proxy
See [how to configure devices](devices.md).

You may also have to trust the certificate served by the
reverse proxy(s) on the device if using HTTPS:

    sudo cp reverse-proxy.crt /usr/local/share/ca-certificates/
    sudo update-ca-certificates
    sudo systemctl restart snapd

At this point, verify that functionality is working as expected for
client devices.

## Add another unit
### Install the snap
To add another unit to our topology, we need to provision a new machine
and install the `enterprise-store` snap, using the same revision
as the other unit. This could mean running the same `install.sh`
script as on the other unit, or finding its revision with:

    snap list enterprise-store

Then install on the new unit with:

    sudo snap install enterprise-store --revision=<revision>

Or for an offline install of a downloaded snap:

    sudo snap ack enterprise-store_<revision>.assert
    sudo snap install enterprise-store_<revision>.snap

After installing, remember to pin the snap:

    sudo snap refresh --hold enterprise-store

### Export and import the config
Next, export the config from the existing enterprise-store unit:

    sudo enterprise-store config --export-yaml | cat > store-config.yaml

```{warning}
Note that this YAML file includes sensitive data like secrets.
```

We also need a copy of the store assertion file at:

    /var/snap/enterprise-store/common/nginx/airgap/store.assert

Next, copy over the `store-config.yaml` and `store.assert` files to
the newly provisioned unit.

On the new unit, import the `store-config.yaml` file:

    cat store-config.yaml | sudo enterprise-store config --import-yaml

Then move the `store.assert` file to the appropriate location:

    sudo cp store.assert /var/snap/enterprise-store/common/nginx/airgap/store.assert

You may also need to repeat any other relevant configuration steps
from the initial unit, such as trusting the S3 certificate.

Verify that the unit is okay:

    enterprise-store status
    enterprise-store check-connections

Next, add the unit to the reverse proxy as a backend. Following the
HAProxy example above, the configuration might look like:

```
backend web_servers
  mode http
  balance roundrobin
  # Add health checks to units
  option httpchk HEAD /_status/check
  server s1 unit-ip-1.test:80 check
  server s2 unit-ip-2.test:80 check
```

Don't forget to restart the reverse proxy to pick up the configuration
changes.

## Existing Enterprise Store
Migrating to HA from an existing, non-HA Enterprise Store is generally
similar to the steps above, but with some key differences, like
updating TLS termination to occur at the reverse proxy and migrating
existing blobs from the single Enterprise Store unit to S3.

First, follow the steps for [configuring the initial
unit](#configure-the-initial-unit), skipping the steps for:
* registration
* setting up a reverse proxy
* connecting to S3

The latter two steps are slightly different when dealing with
an existing Enterprise Store.

Once the above steps are completed, at a high-level, we first need
to need to move the reverse proxy from the internal Nginx instance
on the Enterprise Store unit to an external reverse proxy, and then
switch the traffic of incoming devices/clients to use the newly set
up external reverse proxy.

Then, we move existing blobs from the Enterprise Store snap unit
to S3 storage, before switching the Enterprise Store unit to use S3
as the storage backend.

### Backup
Make a backup and store the file securely:

    sudo enterprise-store config --export-yaml | cat > store-config.yaml

In case something goes wrong, it is possible to revert to a known-good
configuration with:

    cat store-config.yaml | sudo enterprise-store config --import-yaml

### Reverse Proxy
We want to set up a reverse proxy in front of the existing Enterprise
Store snap unit, with devices directing traffic towards the reverse
proxy instead of the Enterprise Store snap unit. This is relatively
simple if using HTTP. However, if using HTTPS, it's a bit more
involved. Please modify the steps as necessary for a HTTP Enterprise
Store. This section assumes the goal of TLS termination occuring at
the reverse proxy.

Copy the certificate and private key from the Enterprise Store unit
to the reverse proxy. These can be obtained with:

    sudo enterprise-store config proxy.tls.cert | cat > enterprise-store.cert
    sudo enterprise-store config proxy.tls.key | cat > enterprise-store.key

```{warning}
The private key should be stored and transferred securely.
```

<!-- These are located at: -->
<!-- /var/snap/enterprise-store/current/nginx/<domain>.cert -->
<!-- /var/snap/enterprise-store/current/nginx/<domain>.key -->

<!-- where `<domain>` is from: -->

<!-- sudo enterprise-store config proxy.domain -->

Use these files to configure the reverse proxy to serve the HTTPS
certificate. For example, with HAProxy, concatenate the two into a
PEM file:

    sudo cat enterprise-store.key enterprise-store.cert | sudo tee /etc/ssl/private/reverse-proxy.pem > /dev/null

Then, use the snap unit as a backend server. In this example, we use
the HTTPS port. Since TLS termination typically occurs at the reverse
proxy in HA setups, skip verification of SSL for the snap unit. In
HAProxy, this could look like:

```
frontend my_frontend
  mode http
  # Use HTTPS
  bind *:443 ssl crt /etc/ssl/private/reverse-proxy.pem
  # Set the X-Forwarded-Proto header appropriately
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  # Uncomment and use section below if using HTTP instead
  # bind *:80
  # http-request add-header X-Forwarded-Proto http if !{ ssl_fc }
  default_backend web_servers

backend web_servers
  mode http
  balance roundrobin
  # Add health checks to units
  option httpchk HEAD /_status/check
  # Use the HTTPS backend and don't verify its certificate
  server s1 unit-ip-1.test:443 ssl verify none check
```

Remember to restart the reverse proxy to pick up the configuration changes.

Verify that traffic to the reverse proxy is working and going to the
snap unit. A simple check could be:

    curl https://<domain>/_status/check

Make the switch so that all traffic from devices/clients goes to the
reverse proxy instead of the Enterprise Store unit. This could mean
editing `/etc/hosts` files or updating DNS. Then, [make the unit
reverse proxy aware](#make-the-unit-reverse-proxy-aware) with:

    sudo enterprise-store config proxy.trust-forwarded-proto="true"

Verify that traffic looks fine.

To make TLS termination occur at the reverse proxy, we need to convert
the snap unit to use HTTP instead of HTTPS. Add a HTTP server to the
unit and point it the snap backend. In HAProxy, this looks like:

```
backend web_servers
  mode http
  balance roundrobin
  # Add health checks to units (important to help with switching
  # units in this example)
  option httpchk HEAD /_status/check
  # Use the HTTPS backend and don't verify its certificate
  server s1 unit-ip-1.test:443 ssl verify none check
  # New server - clients may temporarily be redirected to HTTPS
  # while this is included, despite already being on a HTTPS
  # connection. This may cause temporary issues if clients
  # don't follow redirects.
  server s2 unit-ip-1.test:80 check
```

Restart the reverse proxy. Remove the certificate from the snap unit,
so that it expects HTTP traffic:

    sudo enterprise-store config proxy.tls.key='' proxy.tls.cert=''

Remove the HTTPS backend from the reverse proxy:

```
backend web_servers
  mode http
  balance roundrobin
  # Add health checks to units
  option httpchk HEAD /_status/check
  server s1 unit-ip-1.test:80 check
```

Restart the reverse proxy, and verify that traffic to the reverse
proxy is working as expected.

### S3 (Offline Store)
First, [set the relevant S3 options](#connect-to-s3-offline-store),
but **do not switch over to using S3 as the storage backend** yet.

Package uploads should be avoided during this S3 migration, to prevent
new uploads not being migrated. This can be done by avoiding running
Enterprise Store commands like `push-snap` and `push-charms`, as well
as on-prem publishing operations. Another way would be to temporarily
take the Enterprise Store down for maintenance, either by modifying
the reverse proxy or disabling the snap on the Enterprise Store unit.

#### Migrate scanned package blobs
Scanned blobs can be found on the Enterprise Store unit using:

```{terminal}
:input: ls -1 /var/snap/enterprise-store/common/snapstorage-local/scanned
:copy:
LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap
```

In the example output above, the
`LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap` file needs to be migrated
to the appropriate S3 bucket.

The name of the S3 bucket can be found with:

    sudo enterprise-store config proxy.storage.s3.scanned-container-name

By default, this value is "scanned-production". The next steps assume
"scanned-production" as the value, but this should be replaced as
necessary to match the value from the output of the previous command.

Create the S3 bucket to match this configuration value's name.

Connect to the PostgreSQL database and run:

    SELECT * FROM snapstorage.package_store WHERE path='LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap';
replacing the `path` value as needed with the matching blob name
above. This should yield a record similar to:

```
-[ RECORD 1 ]+------------------------------------------------------------
id           | 1
object_uuid  | 7f802195-e352-46d7-ba15-5a7fe10ef895
path         | LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap
bucket       | /var/snap/enterprise-store/common/snapstorage-local/scanned
content_type | application/octet-stream
object_type  | snap
object_size  | 7897088
mark_deleted | f
when_created | 2025-08-27 02:13:39.159852
```

Keep note of the `object_uuid` field, since this will be the name
of the package blob in the S3 bucket.

Create a new directory on the Enterprise Store unit to store the
renamed package blobs:

    mkdir scanned-production

Copy the package blob into this directory, using the corresponding
`object_uuid` as the name:

    cp /var/snap/enterprise-store/common/snapstorage-local/scanned/LpV8761EjlAPqeXxfYhQvpSWgpxvEWpN_414.snap scanned-production/7f802195-e352-46d7-ba15-5a7fe10ef895

Repeat this for all of the blobs under
`/var/snap/enterprise-store/common/snapstorage-local/scanned`.

Once completed, upload the renamed blobs from the `scanned-production`
directory to the appropriate S3 bucket ("scanned-production" in the
default case), keeping the UUID as the file name. In this example,
the final S3 bucket structure will look like:

    scanned-production/7f802195-e352-46d7-ba15-5a7fe10ef895

Verify that the amount of blobs in the S3 bucket match the count from the
local Enterprise Store unit. The blob count on the unit can be found with:

    ls -1 /var/snap/enterprise-store/common/snapstorage-local/scanned | wc -l

#### Migrate unscanned blobs
Unscanned blobs can be found on the Enterprise Store unit using:

```{terminal}
:input: find /var/snap/enterprise-store/common/snapstorage-local/unscanned/ -type f
:copy:
/var/snap/enterprise-store/common/snapstorage-local/unscanned/e33d585a-cdf3-420e-9b6e-125d069542a5/hello-world_29.snap
```
In the example output above,
`e33d585a-cdf3-420e-9b6e-125d069542a5/hello-world_29.snap` needs
to be migrated to the appropriate S3 bucket. Note that the UUID is
`e33d585a-cdf3-420e-9b6e-125d069542a5` in this example.

The name of the S3 bucket can be found with:

    sudo enterprise-store config proxy.storage.s3.unscanned-container-name

By default, this value is "unscanned-production". The next steps assume
"unscanned-production" as the value, but this should be replaced as
necessary to match the value from the output of the previous command.

Create the S3 bucket to match this configuration value's name.

Create a new directory on the Enterprise Store unit to store the
renamed unscanned blobs:

    mkdir unscanned-production

Copy the blob into this directory, using the corresponding
UUID as the file name:

    cp /var/snap/enterprise-store/common/snapstorage-local/unscanned/e33d585a-cdf3-420e-9b6e-125d069542a5/hello-world_29.snap unscanned-production/e33d585a-cdf3-420e-9b6e-125d069542a5

Repeat this for all of the blobs under
`/var/snap/enterprise-store/common/snapstorage-local/unscanned`.

Once completed, upload the renamed blobs from the `unscanned-production`
directory to the appropriate S3 bucket ("unscanned-production" in the
default case), keeping the UUID as the file name. In this example,
the final S3 bucket structure will look like:

    unscanned-production/e33d585a-cdf3-420e-9b6e-125d069542a5

Verify that the amount of blobs in the S3 bucket match the count from the
local Enterprise Store unit. The blob count on the unit can be found with:

    ls -1 /var/snap/enterprise-store/common/snapstorage-local/unscanned | wc -l

#### Switch to using S3
Make a backup of the `snapstorage.package_store` table in the
PostgreSQL database, to use in case the migration goes wrong. The
next steps will cause some downtime.

Run the DB migration to change the `bucket` names in the
`snapstorage.package_store` table. Similar to the sections above, the
example below assumes the use of the default "unscanned-production" and
"scanned-production" bucket names. Replace these as needed depending
on the chosen bucket names. The example migration is:

```sql
BEGIN;
-- Consider double-checking the state before and after the UPDATEs
-- SELECT * FROM snapstorage.package_store;
UPDATE snapstorage.package_store SET bucket = 'scanned-production' WHERE bucket='/var/snap/enterprise-store/common/snapstorage-local/scanned';
-- SELECT * FROM snapstorage.package_store;
UPDATE snapstorage.package_store SET bucket = 'unscanned-production' WHERE bucket LIKE '/var/snap/enterprise-store/common/snapstorage-local/unscanned%';
-- SELECT * FROM snapstorage.package_store;
COMMIT;
```

Switch to using the S3 backend on the Enterprise Store unit:

    sudo enterprise-store config proxy.storage.backend="s3"

Verify that it works by running:

    enterprise-store status

There should be no failing services, especially
`snapstorage`. Additionally, verify that package downloads are
working as expected.

```{note}
If something goes wrong, revert to the initial state by switching
to the "local" backend:

    sudo enterprise-store config proxy.storage.backend="local"

and restoring to the backup of the `snapstorage.package_store`
table.
```

At this point the initial unit has been configured for HA, so
[additional units can be added](#add-another-unit).

## Keep backups
It is advisable to maintain frequent backups of various components
of the Enterprise Store. These backups include:

* Enterprise Store unit configs (including secrets)
* PostgreSQL data
* S3 data
* Private keys, certificates and configuration of other components
of the network topology (such as reverse proxies, memcached, etc.)

## Keep unit configuration consistent
It is important for the Enterprise Store configuration to be the same
across units within the same cluster. Divergent configurations will likely
lead to divergent behaviour when handling requests.

One way of checking that unit configurations are consistent is to
compare the hash of the configuration options across the units using:

    # Run the following across the units
    sudo enterprise-store config --export-yaml | sha256sum

It is also advisable to ensure that, before and after running commands
on an Enterprise Store unit, you check that the configuration has
not changed. For example:

    # Note the config hash before running the command
    sudo enterprise-store config --export-yaml | sha256sum

    # Could be any command, we're just using `config` as an example
    sudo enterprise-store config proxy.cache.size="4096"

    # Compare the config hash after running the command
    sudo enterprise-store config --export-yaml | sha256sum

In the case of divergent configuration, you should replicate
the desired configuration across the units, following the YAML
export/import instructions from above.
