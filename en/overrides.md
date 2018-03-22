---
title: Snap overrides
table_of_contents: true
---

# Snap revision overrides

You can override the revisions for specific snaps, on a specific
channel. This means you can control the specific revision of a snap in
a channel, rather than what the upstream publisher has released. You can
use this to effectively pin revisions, and control when you are ready to
upgrade to newer revisions.

There are a few different ways to configure overrides.

## Proxy server

You can configure them from the proxy server.

To add an override:

    sudo snapstore override <snap> <channel>=<revision>

To list overrides currently in place:

    sudo snapstore list-overrides <snap>

To remove all current overrides on a channel:

    sudo snapstore delete-override <snap> <channel>

## Overrides API

In addition to managing overrides directly on the server CLI, you
can also manage them via a [REST API](api-overrides.html)


## Command line tool

There is a CLI tool to help manage overrides, which uses the API and can
be used remotely to administer overrides:

    sudo snap install snapstore-client

Authentication is performed using Ubuntu SSO, and users need to be
authorized from the CLI on the server using:

    sudo snapstore add-admin becky@example.com

On the client side, you authenticate by:

    snapstore-client login

Overrides are managed in the same way as with the `snapstore` command
above, e.g.:

    snapstore-client list-overrides
    snapstore-client override foo stable=10
    snapstore-client delete-override foo
