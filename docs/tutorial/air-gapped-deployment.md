# Getting started with an air-gapped store

In this tutorial, we will set up and test the Enterprise Store in a functionally
offline environment. We will cover how to set the store up, how
to make specific snaps available from the store, and how to obtain those snaps
on a connected device.

Once you've completed this tutorial, you should be able to set the Enterprise
Store up in your own air-gapped environment, connect your devices to it, and be
able to use it to control snap revisions on any connected devices.

## Lesson plan

This tutorial will run through processes to set up and utilise an air-gapped
Enterprise Store. We will show you how to:

* Install the Enterprise Store in an offline environment  
* Sideload a snap in an offline environment  
* Obtain a snap from the store in an offline mode

We will also cover how to mimic and air-gapped environment for the containers,
so there's no need to take your host machine offline.

## What you'll need

For this tutorial, you will need:

* An x64 system running Ubuntu 22.04 or Ubuntu 24.04  
* A local user with super user privileges  
* 30GB of free storage  
* A stable internet connection  
* An [Ubuntu One account](https://login.ubuntu.com/)

## Before you begin

Ensure LXD is installed on your **host machine**:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo snap install lxd
```

Ensure LXD is set up properly:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxd init --minimal
```

Launch two containers, **test-offline-store**, and **test-offline-device**:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxc launch ubuntu:22.04 test-offline-store

:input: sudo lxc launch ubuntu:22.04 test-offline-device
```


```{note}
For this tutorial, it is recommended to open each container in a separate terminal tab or window for convenience.
```

````{dropdown} How-to open a container's shell

We can open a container by running bash. For example, to open the CLI of the **test-store**:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxc exec test-offline-store -- bash
```

This will simulate SSH access to the container, and show you as root within the container:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input:
```
````

## Download required software

Normally, you need to obtain software online, and transfer it to your test-offline-store. In this tutorial, we will download the files to the store before taking it offline and then install and set up the store when it is offline.

We want to obtain:

- PostgreSQL, to provide the store's database
- A registered Enterprise Store
- Snaps to make available in the offline store

On the **test-offline-store**, download PostgreSQL:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: snap download postgresql
Fetching snap "postgresql"
Fetching assertions for "postgresql"
Install the snap with:
   snap ack postgresql_62.assert
   snap install postgresql_62.snap

:input: snap download core24
Fetching snap "core24"
Fetching assertions for "core24"
Install the snap with:
   snap ack core24_1055.assert
   snap install core24_1055.snap
```

To obtain a functional Enterprise Store for installation offline, you need to register it while online. This is something done by using the `store-admin` snap and specifically registering an offline store with your Ubuntu One credentials.

On the **test-offline-store**, install the `store-admin` snap: 

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: sudo snap install store-admin
```

Then, register an offline store with the domain to be used offline:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: store-admin register --offline http://test-offline-store
```

```{note}
You may be prompted to open a browser and verify your Ubuntu One account.
```

To sideload a snap into an air-gapped Enterprise Store, you need to use an online device with the store-admin snap installed to export the snap, move it to your air-gapped device, then import it into the store.

On your **test-offline-store**, use `store-admin` to export the `helix` and `htop` snaps:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: store-admin export snaps helix htop --channel=stable --arch=amd64 --arch=arm64 --export-dir .
```

```{note}
`store-admin` is used to export snaps in a convenient bundle.
```

## Mimic an air-gapped network

To effectively set up and test the Enterprise Store in an air-gapped environment,
we need to ensure that the devices within that environment cannot contact
external services.

To do that, we are going to set firewall rules to ensure the containers can only
communicate with each other, and your host machine.

From your **host machine**, use `iptables` to isolate our LXC containers:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo iptables -I FORWARD -i lxdbr0 -j REJECT

:input: sudo iptables -I FORWARD -i lxdbr0 -o lxdbr0 -j ACCEPT
```

```{note}
This adds these two settings to the top of the `FORWARD` chain of `iptables`, which means they are processed first.

See the {ref}`cleanup2` section on how to revert this setting.
```

This will ensure that your **test-offline-store** and **test-offline-device** cannot
access external services. You can test this to make sure.

Test access to `api.snapcraft.io` on your host machine:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: curl api.snapcraft.io

snapcraft.io store API service - Copyright 2018-2022 Canonical.
```

Compare it to the same command used in **test-offline-store**:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: curl api.snapcraft.io

curl: (7) Failed to connect to api.snapcraft.io port 80 after 4103 ms: Network is unreachable
```

## Install your offline store

In **test-offine-store**, install PostgreSQL: 

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: snap ack /root/postgresql_62.assert

:input: snap install /root/postgresql_62.snap
```

In **test-offline-store**, unzip the store:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: tar -xvzf offline-snap-store.tar.gz

:input: cd offline-snap-store
```

Then use the install script, and verify the installation:

```{terminal}
:user: root
:host: test-offline-store
:dir: /offline-snap-store
:copy:
:input: ./install.sh

:input: enterprise-store status

Store URL: http://test-offline-store
Store DB: not configured (check the installation guide at http://localhost/docs/ or visit https://docs.ubuntu.com/enterprise-store/en/install#database)
```

Next, configure PostgreSQL for use with the Enterprise Store:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: nano ~/proxydb.sql
```

Copy the following into `~/proxydb.sql`, and save the file:

```
CREATE ROLE "snapproxy-user" LOGIN CREATEROLE PASSWORD 'snapproxy-password';
CREATE DATABASE "snapproxy-db" OWNER "snapproxy-user";
\connect "snapproxy-db"
CREATE EXTENSION "btree_gist";
```

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: cp ~/proxydb.sql /var/snap/postgresql/common/

:input: snap run postgresql.psql -U postgres -f /var/snap/postgresql/common/proxydb.sql
:input: enterprise-store config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db?sslmode=disable"
```

When prompted, enter the password set in `~/proxydb.sql`, `snapproxy-password`.

Check the status of the store again:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: enterprise-store status

Store URL: http://test-offline-store
Store DB: ok

...
```

The Enterprise Store should now be fully set up and configured.

## Sideloading a snap

Snaps in the offline Enterprise Store need to be sideloaded. Normally they need to be transferred from an online environment, but in this case we have already downloaded the snaps we want to test.

On the **test-offline-store**, push the helix snap to the Enterprise Store:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: enterprise-store push-snap /root/helix-*.tar.gz

[snap helix] Uploaded snap blob and assertions for helix revision 120
[snap helix] Uploaded snap blob and assertions for helix revision 121
[snap helix] Channelmaps were successfully updated.
```

Check that the snaps have been successfully pushed to the store:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: enterprise-store list-pushed-snaps

Name    Stores
helix   ubuntu
```

Now our air-gapped Enterprise Store is set up with multiple snaps available for connected devices to obtain.

## Offline device configuration

To properly test an air-gapped Enterprise Store, we need a device that also can't connect to any online services. In this section, we'll make some adjustments to the test-device to properly validate our air-gapped store.

Ensure **test-offline-device** cannot access any online services:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: curl api.snapcraft.io

curl: (7) Failed to connect to api.snapcraft.io ...
```

Configure **test-offline-device** to use the air-gapped Enterprise Store:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: curl -sL http://test-offline-store/v2/auth/store/assertions | snap ack /dev/stdin

:input: snap known store
type: store
authority-id: canonical
store: ndOhjHBJfSf386KSGV0AH6oApdTuwGTy
operator-id: 2SZDATTNFeUoIOOrDiKgDpjMFv3YAR1M
timestamp: 2025-09-05T01:52:05.689607Z
url: http://test-offline-store

...

:input: snap set core proxy.store=$(snap known store | awk '/store:/{print $2}')
```

Now our device is configured to use the air-gapped Enterprise Store.

## Using your air-gapped Enterprise Store

In this section we want to validate that the store can be used by your device. All we want to do is to install the snaps we pushed on the **test-offline-device**.

Use **test-offline-device** to query the snaps, starting with `helix`:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: snap info helix

name:      helix
summary:   Helix is a modal text editor inspired by Vim and Kakoune
publisher: Lauren Brock
store-url: https://snapcraft.io/helix
license:   MPL-2.0
description: |
  
snap-id: JbSwFezsVhBG8EpYeNqD4HX31U5WIzdY
channels:
  latest/stable:    25.07.1 2025-09-05 (120) 21MB classic
  latest/candidate: ↑                             
  latest/beta:      ↑                             
  latest/edge:      ↑ 
```

Check if `htop` is available:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: snap info htop

error: no snap found for "htop"
```

```{note}
This will fail, as `htop` has not been pushed to the Enterprise Store.
```

Finally, install the `helix` snap to verify functionality:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: snap install helix --classic

helix 25.07.1 from Lauren Brock installed
```

(cleanup2)=
## Cleanup

We've tried to keep the impact on your **host machine** minimal, but there are some iptable rules and a few LXC containers to clean up.

On your **host machine**, delete the firewall rules we created for offline testing:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo iptables -D FORWARD -i lxdbr0 -j REJECT

:input: sudo iptables -D FORWARD -i lxdbr0 -o lxdbr0 -j ACCEPT
```

And then delete the containers we created for this tutorial:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxc delete test-offline-device --force

:input: sudo lxc delete test-offline-store --force
```

This should return your system to the state it was in before this tutorial.

## Next steps

Once you've completed this tutorial, you might be interested in how to implement {doc}`High Availability </how-to/high-availability>`, or {doc}`serve Charms </how-to/charmhub-proxy>` with your Enterprise Store.