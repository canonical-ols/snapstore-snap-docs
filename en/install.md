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

    sudo snap-proxy config proxy.db.connection="postgresql://snapproxy-db@localhost:5432/snapproxy-db"

After doing this, you will be prompted to enter the password for that PostgreSQL
user.

[The connection string format is detailed in the libpq documentation](https://www.postgresql.org/docs/current/static/libpq-connect.html#LIBPQ-CONNSTRING).

## Network connectivity

You can check that the Proxy can access all the network locations it
needs to with:

    snap-proxy check-connections

If you require traffic between your Snap Store Proxy and the internet to go via
another HTTP proxy, you can configure your Snap Store Proxy to do so with:

    sudo snap-proxy config proxy.https.proxy=myproxy.internal:3128

## Next step

If you want traffic between your devices and your Snap Store Proxy to be
encrypted, continue to [HTTPS](https.md). Otherwise, proceed with
[registration](register.md).

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
