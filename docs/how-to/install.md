---
title: Install
table_of_contents: true
---

# Installation

## Prerequisites

To run the Enterprise Store, you will need:

* A server running one of the [currently supported LTS versions of Ubuntu](https://ubuntu.com/about/release-cycle) on AMD64.
* [Firewall rules configured to allow traffic to servers](https://forum.snapcraft.io/t/network-requirements/5147).
* A domain name for the server.
* A PostgreSQL instance (see the Database section). 

## Getting started

First, if your network requires an HTTPS proxy to get to the above
domains, you must first configure `snapd` on the installation server to
use that HTTPS proxy in order to be able to install the enterprise-store snap
package.

Do this by adding the appropriate environment variables (`http_proxy`,
`https_proxy`) to the server’s `/etc/environment` file, and restarting
`snapd`:

    sudo systemctl restart snapd

Installing the stable release of the Enterprise Store is as simple as:

    sudo snap install enterprise-store

This will install the snap, which provides a collection of systemd
services, and the `enterprise-store` CLI tool to control the proxy.

## Domain configuration

The Enterprise Store will require a domain or IP address to be set
for the configuration and access by other devices, e.g.:

    sudo enterprise-store config proxy.domain="proxy.example.com"

This can be done after the database is created, but is required
before registration can succeed.

## Port configuration

You can optionally change the ports that the Enterprise Store or its internal services
listen on. 

For example, to change the internal `snapdevicegw` service to listen on a different 
port, run:

    sudo enterprise-store config proxy.port.snapdevicegw=9000

The port for the Enterprise Store's external URL, corresponding to `proxy.port.http` (or 
`proxy.port.https` if registered with `--https`), must be set before registration to 
ensure that the store is registered with the correct URL. 

```{dropdown} Available port configuration options
As of the time of writing, these are all the available port configuration options
with their defaults.

    proxy.port.http: 80
    proxy.port.https: 443
    proxy.port.memcached: 11211
    proxy.port.packagereview: 8006
    proxy.port.publishergw: 8010
    proxy.port.snapassert: 5000
    proxy.port.snapauth: 8005
    proxy.port.snapdevicegw: 8000
    proxy.port.snapident: 8001
    proxy.port.snapmodels: 8007
    proxy.port.snaprevs: 8002
    proxy.port.snapstorage: 8011
    proxy.port.storeadmingw: 8013
```

## Database

When setting up an Enterprise Store for production usage, we recommend you have a
properly configured PostgreSQL service set up, with backups and possibly HA.
However, if you are evaluating the Enterprise Store or using it in a local
deployment, you can use a local PostgreSQL.

The example below illustrates the expected PostgreSQL set up in terms of a role,
database, and a database extension that are required by the Enterprise Store.

### Example database setup

Ensure that proper PostgreSQL database, user and database extensions are set up.
This can be done by adjusting the following script to your needs and running it
using `psql` as your PostgreSQL server **superuser**:

    CREATE ROLE "snapproxy-user" LOGIN CREATEROLE PASSWORD 'snapproxy-password';

    CREATE DATABASE "snapproxy-db" OWNER "snapproxy-user";

    \connect "snapproxy-db"

    CREATE EXTENSION "btree_gist";

Simple local Ubuntu setup can look like this:

1. Install PostgreSQL

        sudo apt install postgresql

2. Save the above PostgreSQL script as `proxydb.sql` and run it:

        sudo -u postgres psql < proxydb.sql

### Configure the Enterprise Store database

Once the database is prepared, set the connection string:

    sudo enterprise-store config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db"

After doing this, you will be prompted to enter the password for that PostgreSQL
user.

[The connection string format is detailed in the libpq documentation](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING).

## Network connectivity

You can check that the Proxy can access all the network locations it
needs to with:

    enterprise-store check-connections

If you require traffic between your Enterprise Store and the internet to go via
another HTTP proxy, you can configure your Enterprise Store to do so with:

    sudo enterprise-store config proxy.https.proxy="https://myproxy.internal:3128"

Enterprise Store also uses the `https_proxy` environment variable if it's set.
`http_proxy` is ignored as all outgoing traffic is encrypted.

## CA certificates

For verifying outgoing HTTPS communication, Enterprise Store bundles a set of
root [CAs](https://en.wikipedia.org/wiki/Certificate_authority) from its base
Ubuntu based snap.

On Ubuntu, the system trust store can be modified using `update-ca-certificates`
as needed and enterprise-store will honour these changes by default (it might
require a restart `sudo snap restart enterprise-store`).

You can also override this default behaviour and configure your Enterprise Store
to _only_ trust a specific list of CAs:

    cat your-ca.crt another-ca.crt | sudo enterprise-store use-ca-certs

This can be useful in cases when you want your Enterprise Store to only trust
your internal CA for example.

To reset the CA certificates back to the system defaults, run:

    sudo enterprise-store remove-ca-certs

## Next step

[Register](register.md) your Enterprise Store.
