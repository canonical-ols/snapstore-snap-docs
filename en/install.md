---
title: Installation
table_of_contents: true
---

# Installation

## Prerequisites

To run the Snap Store Proxy, you will need:

* A server running Ubuntu 16.04 LTS on AMD64.
* The ability (e.g. firewall rules) for the server to initiate network
  connections to https://api.snapcraft.io,
  https://public.apps.ubuntu.com, and https://login.ubuntu.com.
* A domain name for the server.
* A PostgreSQL instance (see the Database section). 
* An RSA key pair to register the snap-store-proxy identity (these can be
  generated for you with: `snap-proxy generate-keys`).

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
for the configuration and access by other devices.

    sudo snap-proxy config proxy.domain="<domain>"

This can be done after the database is created, but is required
before registration can succeed.

The proxy will listen on all interfaces on port 443 (with a redirect from 80).

## Database

To initially configure the Snap Store Proxy, you will need either a
database already prepared, or the ability to install PostgreSQL locally. 

### Prepared database

Choose this approach if you are experience with PostgreSQL and want to setup a
production ready installation.

You will need to create a database:
    CREATE DATABASE dbname;

And a new user:
    CREATE ROLE user LOGIN CREATEROLE PASSWORD password;

The user needs to be able to create objects in the database:
    GRANT CREATE ON dbname TO user;

A prepared database must have the 
[btree_gist](https://www.postgresql.org/docs/current/static/btree-gist.html) 
extension installed. This extension requires superuser privileges to create.
You should connect to DBNAME as a superuser and create the extension:
    CREATE EXTENSION btree_gist;

Once the database is prepared, set the connection string.
    sudo snap-store-proxy config \
        proxy.db.connection="postgresql://USER:PASSWORD@HOST:PGPORT/DBNAME"

The connection string behaves as per [normal PostgreSQL
clients](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING)

### Creating a database

There is a convenience option that will guide you through creating and 
configuring the database.

It assumes you will install PostgreSQL locally on Ubuntu:
    sudo apt install postgresql

Once PostgreSQL is install create the snapstore admin user.
You need to choose a good password for PASSWORD.
    echo 'CREATE ROLE snapstore LOGIN PASSWORD '\''PASSWORD'\'';' | \
        sudo su - postgres -c psql

Now run create-database. It's necessary to run it multiple times. 
Follow the instructions it gives:
    sudo snap-store-proxy create-database \
        "postgresql://snapstore:PASSWORD@localhost:5432/snapstore"

This will setup and configure the database.

The connection string behaves as per [normal PostgreSQL clients](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING). i.e.
`USER` will default to 'root', `HOST` defaults to 'localhost', `PGPORT` defaults to '5432', `DBNAME` defaults to `USER`. The `PASSWORD` here is optional, and if needed will be prompted for by the command (to avoid leaving credentials in your shell's history).

## Network connectivity

You can check that the Proxy can access all the network locations it
needs to with:

    snap-proxy check-connections

If you require an HTTPS proxy, you can configure the proxy to use that
with:

    sudo snap-proxy config proxy.https.proxy=myproxy.internal:3128

## Next step

With the domain set, and database configured your proxy should now be
ready to be [registered](register.md).


## Running multiple proxies

You can run multiple instances of the proxy for HA, provided by simple
round-robin DNS. All instances need to have the same configuration,
using your normal configuration management system. Once a key pair has
been registered, it will not need registering on other instances.

!!! NOTE:
    The download caching will currently be less efficient when
    running multiple instances, as the instances are not aware of each
    other. Support for shared caching is planned for later releases of the
    Snap Store Proxy.
