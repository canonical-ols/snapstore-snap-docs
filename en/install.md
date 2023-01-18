---
title: Installation
table_of_contents: true
---

# Installation

## Prerequisites

To run the Snap Store Proxy, you will need:

* A server running Ubuntu 18.04 LTS or newer on AMD64.
* Firewall rules configured to allow traffic to servers mentioned at https://forum.snapcraft.io/t/network-requirements/5147.
* A domain name for the server.
* A PostgreSQL instance (see the Database section). 

## Getting started

First, if your network requires an HTTPS proxy to get to the above
domains, you must first configure snapd on the installation server to
use that HTTPS proxy in order to be able to install the snap-store-proxy snap
package.

Do this by adding the appropriate environment variables (`http_proxy`,
`https_proxy`) to the server’s `/etc/environment` file, and restarting
snapd:

    sudo systemctl restart snapd

Installing the stable release of the Snap Store Proxy is as simple as:

    sudo snap install snap-store-proxy

This will install the snap, which provides a collection of systemd
services, and the `snap-proxy` CLI tool to control the proxy.

## Domain configuration

The Snap Store Proxy will require a domain or IP address to be set
for the configuration and access by other devices, e.g.:

    sudo snap-proxy config proxy.domain="snaps.myorg.internal"

This can be done after the database is created, but is required
before registration can succeed.

## Database

When setting up a Snap Store Proxy for production usage, we recommend you have a
properly configured PostgreSQL service set up, with backups and possibly HA.
However, if you are evaluating the Snap Store Proxy or using it in a local
deployment, you can use a local PostgreSQL.

The example below illustrates the expected PostgreSQL set up in terms of a role,
database, and a database extension that are required by the Snap Store Proxy.

### Example database setup

Ensure that proper PostgreSQL database, user and database extensions are set up.
This can be done by adjusting the following script to your needs and running it
using `psql` as your PostgreSQL server **superuser**:

    CREATE ROLE "snapproxy-user" LOGIN CREATEROLE PASSWORD 'snapproxy-password';

    CREATE DATABASE "snapproxy-db" OWNER "snapproxy-user";

    \connect "snapproxy-db"

    CREATE EXTENSION "btree_gist";

Simple local Ubuntu setup can look like this:

1. Install postgresql

        sudo apt install postgresql

2. Save the above PostgreSQL script as proxydb.sql and run it:

        sudo -u postgres psql < proxydb.sql

### Configure the Snap Store Proxy database

Once the database is prepared, set the connection string:

    sudo snap-proxy config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db"

After doing this, you will be prompted to enter the password for that PostgreSQL
user.

[The connection string format is detailed in the libpq documentation](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING).

## Network connectivity

You can check that the Proxy can access all the network locations it
needs to with:

    snap-proxy check-connections

If you require traffic between your Snap Store Proxy and the internet to go via
another HTTP proxy, you can configure your Snap Store Proxy to do so with:

    sudo snap-proxy config proxy.https.proxy="https://myproxy.internal:3128"

Snap Store Proxy also uses the `https_proxy` environment variable if it's set.
`http_proxy` is ignored as all outgoing traffic is encrypted.

## CA certificates

For verifying outgoing HTTPS communication, Snap Store Proxy bundles a set of
root [CAs](https://en.wikipedia.org/wiki/Certificate_authority) from
[The Certifi Trust Database](https://certifi.io/).

You can override this default behavior and configure your Snap Store Proxy to
only trust a specific list of CAs:

    cat your-ca.crt another-ca.crt | sudo snap-proxy use-ca-certs

This can be useful in cases when you want your Snap Store Proxy to trust your
internal CA for example.

To reset CA certificates back to defaults, run:

    sudo snap-proxy remove-ca-certs

## Next step

[Register](register.md) your Snap Store Proxy.

## Running multiple proxies

You can run multiple instances of the Snap Store Proxy, load balanced using
round-robin DNS. All instances need to have the same configuration and connect
to the same shared database. Once a key pair has been registered, it will not
need registering on other instances.

!!! NOTE:
    The download caching will currently be less efficient when
    running multiple instances, as the instances are not aware of each
    other. Support for shared caching is planned for later releases of the
    Snap Store Proxy.
