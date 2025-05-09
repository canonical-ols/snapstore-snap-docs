---
title: Override snap revisions
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

To configure overrides from the proxy server, use the `enterprise-store` command.

To add an override:

    sudo enterprise-store override <snap> <channel>=<revision>

To list overrides currently in place:

    sudo enterprise-store list-overrides <snap>

To remove all current overrides on a channel:

    sudo enterprise-store delete-override <snap> <channel>

### Revisions and Architectures

A Snap Store channel can publish only one
[revision](https://snapcraft.io/docs/getting-started) of a specific snap at any
time.

A snap revision can support one or multiple architectures. Specifying a revision
for an override therefore also determines which architectures the override is
set for.

Revisions for specific snaps can be looked up using the `snap info` command,
which lists currently available revisions for the architecture of the device
running this command. Snap Store's Devices API
[snaps_info](https://api.snapcraft.io/docs/info.html) endpoint can also be used
to obtain available revisions for selected architectures.

In the example below, we have the `core18` snap and two revisions, each
supporting one architecture.

```
# 1722 is one of the amd64 revisions of the core18 snap.
$ sudo enterprise-store override core18 stable=1722
core18 stable amd64 1722

# 1725 is one of the armhf revisions of the core18 snap.
$ sudo enterprise-store override core18 stable=1725
core18 stable armhf 1725

# We can see that we've overriden the stable channel revisions for both
# amd64 and armhf and that both upstream counterparts ar at lower revisions.
$ sudo enterprise-store list-overrides core18
core18 stable amd64 1722 (upstream 1705)
core18 stable armhf 1725 (upstream 1706)

# Deleting a channel-specific override deletes overrides for all revisions
# and architectures.
$ sudo enterprise-store delete-override core18 stable
core18 stable amd64 is tracking upstream (revision 1705)
core18 stable armhf is tracking upstream (revision 1706)
```

## Overrides API

Alternatively, you can also manage overrides via a [REST API](../reference/api-overrides.md)


## Command line tool

There is a [CLI tool](https://snapcraft.io/snap-store-proxy-client) to
help manage overrides, which uses the API and can be used remotely to
administer overrides:

    sudo snap install snap-store-proxy-client

Authentication is performed using Ubuntu SSO, and users need to be
authorised from the CLI on the server using:

    sudo enterprise-store add-admin becky@example.com

On the client side, you authenticate by:

    snap-store-proxy-client login

Overrides are managed in the same way as with the `enterprise-store` command
above, e.g.:

    snap-store-proxy-client list-overrides
    snap-store-proxy-client override foo stable=10
    snap-store-proxy-client delete-override foo
