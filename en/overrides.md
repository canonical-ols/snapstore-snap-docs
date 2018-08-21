---
title: Snap overrides
table_of_contents: true
---

# Snap revision overrides

You can override the revisions for specific snaps, on a specific
[channel](https://docs.snapcraft.io/reference/channels). This means
you can control the specific revision of a snap in a channel, rather
than what the upstream publisher has released. You can use this to
effectively pin revisions, and control when you are ready to upgrade
to newer revisions.

There are a few different ways to configure overrides.

## Proxy server

To configure overrides from the proxy server, use the `snap-proxy` command.

To add an override:

    sudo snap-proxy override <snap> <channel>=<revision>

To list overrides currently in place:

    sudo snap-proxy list-overrides <snap>

To remove all current overrides on a channel:

    sudo snap-proxy delete-override <snap> <channel>

## Overrides API

Alternatively, you can also manage overrides via a [REST API](api-overrides.md)


## Command line tool

There is a [CLI tool](https://snapcraft.io/snap-store-proxy-client) to
help manage overrides, which uses the API and can be used remotely to
administer overrides:

    sudo snap install snapstore-client

Authentication is performed using Ubuntu SSO, and users need to be
authorized from the CLI on the server using:

    sudo snap-proxy add-admin becky@example.com

On the client side, you authenticate by:

    snapstore-client login

Overrides are managed in the same way as with the `snap-proxy` command
above, e.g.:

    snapstore-client list-overrides
    snapstore-client override foo stable=10
    snapstore-client delete-override foo
