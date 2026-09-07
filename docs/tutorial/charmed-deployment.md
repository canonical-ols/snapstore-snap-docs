---
title: Get started with a charmed Enterprise Store
description: A step-by-step tutorial for deploying an Enterprise Store charm, connecting a device, and validating the connection.
---

# Get started with a charmed Enterprise Store

In this tutorial, we will deploy an Enterprise Store with Juju 3.x, connect a
device to it, and verify that the device can obtain a snap through the store.
Once complete, you will have a registered Enterprise Store running with a
PostgreSQL database in a local LXD model.

## Lesson plan

We will show you how to:

* Set up a Juju controller on LXD
* Register an Enterprise Store with `store-admin`
* Deploy the Enterprise Store charm with PostgreSQL
* Connect a device to the store
* Validate the connection
* Clean up the tutorial environment

## What you'll need

For this tutorial, you will need:

* An x64 system running Ubuntu 22.04 LTS or Ubuntu 24.04 LTS
* A local user with super user privileges
* 30 GB of free storage
* A stable internet connection
* An [Ubuntu One account](https://login.ubuntu.com/)

## Before you begin

Install and initialise LXD on your **host machine**. Juju requires an LXD
storage pool, which the automatic initialisation creates:

```{terminal}
:user: user
:host: host
:copy:

sudo snap install lxd
sudo lxd init --auto
```

Install Juju 3.x, bootstrap a controller, and create a model:

```{terminal}
:user: user
:host: host
:copy:

sudo apt install nscd
sudo snap install juju
juju bootstrap localhost tutorial-controller
juju add-model charmed-store
```

```{note}
The Juju snap is strictly confined and cannot access the host's SSSD/NSS
sockets directly. Installing `nscd` makes the host's NSS lookups available to
the snap through its cache socket.
```

## Register the store

Install `store-admin`, then register the domain that the test device will use:

```{terminal}
:user: user
:host: host
:copy:

sudo snap install store-admin
store-admin register http://test-store > registration_bundle.b64
```

Registration prompts you to authenticate with Ubuntu One in a browser. See
{doc}`how to register </how-to/register>` for more information. 

```{warning}
The domain is embedded in the store assertion. Register the domain that devices
will use, and ensure that those devices can resolve it.
```

## Deploy the charmed Enterprise Store

Deploy PostgreSQL and the Enterprise Store, then integrate them. The charm is
currently published in the `latest/edge` channel:

```{terminal}
:user: user
:host: host
:copy:

juju deploy postgresql --channel 14/stable
juju config postgresql plugin_btree_gist_enable=true
juju deploy enterprise-store --channel edge
juju integrate postgresql:database enterprise-store:database
juju config enterprise-store \
    registration_bundle="$(cat registration_bundle.b64)"
```

Watch the deployment settle:

```{terminal}
:user: user
:host: host
:copy:

juju status --watch 5s
```

Before both requirements are available, the Enterprise Store unit can report
`Missing database relation` or `The unit is not registered, please supply a
registration_bundle`. When ready, its status is `Running on:
http://test-store`. Press **Ctrl+C** to stop watching.

### Resolve the store name from its unit

The registered domain is also the value of the Enterprise Store's
`proxy.domain` configuration. The status action connects to that URL from the
Enterprise Store unit, so `test-store` must resolve from the unit as well as
from client devices. Find the Enterprise Store unit's IP address in `juju
status`, replace `<STORE_UNIT_IP>` with that address, and add a temporary host
entry to the unit:

```{terminal}
:user: user
:host: host
:copy:

juju status
juju ssh enterprise-store/leader \
    'sudo sh -c '\''printf "%s test-store\\n" "<STORE_UNIT_IP>" >> /etc/hosts'\'''
```

In a production deployment, configure DNS for the registered domain instead of
adding a host entry. If `test-store` does not resolve from the unit, the status
action reports `Temporary failure in name resolution` after the Store URL.

## Check the store status

Run the charm's status action:

```{terminal}
:user: user
:host: host
:copy:

juju run enterprise-store/leader status

Store URL: http://test-store
Store DB: ok
Store ID: <STORE_ID>
...
```

Record the Store ID for the device configuration.

## Connect a device to the store

Launch the test device:

```{terminal}
:user: user
:host: host
:copy:

sudo lxc launch ubuntu:22.04 test-device
```

Use the Enterprise Store unit's IP address from the earlier `juju status` output
to make the registered name resolvable in the container. Replace
`<STORE_UNIT_IP>` with that address:

```{terminal}
:user: user
:host: host
:copy:

juju status
sudo lxc exec test-device -- sh -c \
    'printf "%s test-store\\n" "<STORE_UNIT_IP>" >> /etc/hosts'
```

Open a shell in **test-device** in a separate terminal:

```{terminal}
:user: user
:host: host
:copy:

sudo lxc exec test-device -- bash
```

Fetch and acknowledge the store assertion from the **test-device**:

```{terminal}
:user: root
:host: test-device
:copy:

curl -sL http://test-store/v2/auth/store/assertions | snap ack /dev/stdin
snap known store
```

Configure the device to use the Store ID in that assertion:

```{terminal}
:user: root
:host: test-device
:copy:

snap set core proxy.store=$(snap known store | awk '/store:/{print $2}')
```

## Set an overwrite to check functionality

We'll use the `jq` snap to test the store's functionality, so we want to set a {doc}`version override </how-to/overrides>`
to ensure our actions impact attached devices. On the host machine, set the override in Juju:

```{terminal}
:user: user
:host: host
:copy:

juju ssh enterprise-store/leader -- sudo enterprise-store override jq stable=11
```

```{note}
Run `snap info jq` and use a revision on a non-stable channel.
```

## Validate the connection

Confirm that the configured value matches the Store ID recorded earlier:

```{terminal}
:user: root
:host: test-device
:copy:

snap get core proxy.store

<STORE_ID>
```

Query and install `jq` through the charmed store:

```{terminal}
:user: root
:host: test-device
:copy:

snap info jq
snap install jq
```

The `snap info` output should contain channel information, and the installation
should succeed. To control the revision supplied to devices, see
{doc}`Override snap revisions </how-to/overrides>`.

## Cleanup

Destroy the controller and all its models, then delete the test device:

```{terminal}
:user: user
:host: host
:copy:

juju destroy-controller tutorial-controller --destroy-all-models
sudo lxc delete test-device --force
sudo apt remove nscd
```

You can optionally remove the `juju`, `lxd`, and `store-admin` snaps from the
host if you no longer need them.

## Next steps

* {doc}`Deploy an offline charmed store </how-to/deploy-charmed-offline>`
* {doc}`Deploy a highly available charmed store </how-to/deploy-charmed-ha>`
* {doc}`Override snap revisions </how-to/overrides>`
