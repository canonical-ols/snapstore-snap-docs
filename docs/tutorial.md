# Enterprise Store tutorial

In this tutorial, we will set up and test the Enterprise Store in an online and
a functionally offline environment. We will cover how to set the store up, how
to make specific snaps available from the store, and how to obtain those snaps
on a connected device.

Once you've completed this tutorial, you should be able to set the Enterprise
Store up in your own environment, connect your devices to it, and be able to use
it to control snap revisions on those connected devices.

## Lesson plan

This tutorial will run through basic processes to set up and utilise an
Enterprise Store. We will show you how to:

* Install the Enterprise Store in an online environment  
* Register your store  
* Pin a revision within the store  
* Connect a device to the store  
* Obtain a snap from the store in proxy mode

We will also run through how to:

* Install the Enterprise Store in an offline environment  
* Sideload a snap in an offline environment  
* Obtain a snap from the store in an offline mode

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

Launch four containers, **test-store**, **test-device**, **test-offline-store**, and **test-offline-device**:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxc launch ubuntu:22.04 test-store

:input: sudo lxc launch ubuntu:22.04 test-offline-store
:input: sudo lxc launch ubuntu:22.04 test-device
:input: sudo lxc launch ubuntu:22.04 test-offline-device
```


```{note}
For this tutorial, it is recommended to open each container in a separate terminal tab or window for convenience.
```

````{dropdown} How-to open a container's shell

We can open a container by running bash. For example, to open the CLI of the **test-store**:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: sudo lxc exec test-store -- bash
```

This will simulate SSH access to the container, and show you as root within the container:

```{terminal}
:user: root
:host: test-store
:copy:
:input:
```
````

```{warning}
In addition to these containers, we will also use your host computer to facilitate transferring files to the “offline” containers.
```

Create a directory, and enter it for this tutorial: 

```{terminal}
:user: user
:host: host
:copy:
:input: mkdir ~/enterprise-store-tutorial && cd ~/enterprise-store-tutorial
```

## Enterprise Store installation

Within the **test-store** container, install the Enterprise Store snap and verify the installation:

```{terminal}
:user: root
:host: test-store
:copy:
:input: sudo snap install enterprise-store

:input: snap list enterprise-store


```

Next, configure the domain for Enterprise Store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: hostname
test-store

:input: sudo enterprise-store config proxy.domain="test-store" 
```

```{warning}
During the registration step later, the domain value will be embedded in a store assertion that devices use to securely connect to your enterprise store. Make sure the desired value is set before registering.
```

Set up a database for the Enterprise Store. This requires installing and configuring PostgreSQL.

Install PostgreSQL:

```{terminal}
:user: root
:host: test-store
:copy:
:input: sudo snap install postgresql
```

Configure database for use with the Enterprise Store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: nano proxydb.sql
```

Paste the contents of the following into proxydb.sql.

```text
CREATE ROLE "snapproxy-user" LOGIN CREATEROLE PASSWORD 'snapproxy-password';
CREATE DATABASE "snapproxy-db" OWNER "snapproxy-user";
\connect "snapproxy-db"
CREATE EXTENSION "btree_gist";
EOF
```

Save the file with **ctrl + x** and press **y** and then **enter** when prompted.


```{terminal}
:user: root
:host: test-store
:copy:
:scroll:
:input: cp ~/proxydb.sql /var/snap/postgresql/common/

:input: snap run postgresql.psql -U postgres -f /var/snap/postgresql/common/proxydb.sql
:input: enterprise-store config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db?sslmode=disable"
:input: services postgresql
:input: run postgresql.psql -U postgres -d snapproxy-db
```

You will be prompted for a password, enter “snapproxy-password”. Then configure the Enterprise Store to use the database.

```{terminal}
:user: root
:host: test-store
:copy:
:input: sudo enterprise-store config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db?sslmode=disable"

:input: snap services postgresql
```

You should now have the Enterprise Store installed, a valid domain provided by LXD, and a database configured for your store.

## Enterprise Store registration

Within the **test-store** container, register your Enterprise Store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: sudo enterprise-store register
```

```{note}
Registering your store will require you to provide some information when prompted. After all information is provided, an ID will be provided for your store.
```

Use the `status` command to retrieve the ID of your store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store status

Store URL: http://test-store
Store DB: ok
Store ID: <STORE_ID>
Status: approved

...
```

Your Enterprise Store is now up and running, now we can connect devices to and install snaps from it.

## Connect a device to the store

From within the **test-device** container, connect to your Enterprise Store and acknowledge the store assertion of the Enterprise Store:

```{terminal}
:user: root
:host: test-device
:copy:
:input: curl -sL http://test-store/v2/auth/store/assertions | sudo snap ack /dev/stdin
```

Verify the assertion on your device:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap known store

type: store
authority-id: canonical
store: <STORE_ID>
operator_id: <OPERATOR_ID>
timestamp: <TIMESTAMP>
url: http://test-store

...

```

Configure **test-device** to use the store:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap set core proxy.store=<STORE_ID>
```

Check the store is configured:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap get core proxy.store

<STORE_ID>
```

```{note}
This process obtains the store assertion from the **test-store** and adds that assertion to the system assertion database so the device can trust the store.
```

## Pin a revision in the store

The Enterprise Store acts as a proxy for the SaaS Snap Store, allowing you to override revisions in a channel for specific snaps. This allows us to control what can be installed on connected devices. In this tutorial we will use the `jq` snap.

Within the **test-device**, query the available jq version:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap info jq

... 

channels:
  latest/stable:    1.5+dfsg-1 2017-05-17  (6) 245kB -
  latest/candidate: 1.5+dfsg-1 2017-05-17  (6) 245kB -
  latest/beta:      1.6        2018-11-19 (11)   1MB -
  latest/edge:      1.6        2022-07-14 (19)   1MB -
installed:          1.5+dfsg-1             (6) 245kB -
```

This shows the revisions of the snap set for the available channels.

Next, within the **test-store**, add an override for the `jq` snap:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store override jq stable=11
```

Ensure the override is set properly:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store list-overrides jq
```

From the **test-device**, query the `jq` snap:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap info jq

... 

channels:
  latest/stable:    1.6        2018-11-19 (11)   1MB -
  latest/candidate: 1.5+dfsg-1 2017-05-17  (6) 245kB -
  latest/beta:      1.6        2018-11-19 (11)   1MB -
  latest/edge:      1.6        2022-07-14 (19)   1MB -
installed:          1.5+dfsg-1             (6) 245kB -
```

This shows the override in place, providing revision 11 in the latest/stable channel.

## Download a snap from the store

We have verified that the `jq` snap has been overridden, but does this successfully change what is downloaded on a device connected to the store?

Using **test-device**, try downloading the `jq` snap: 

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap install jq

jq 1.6 from Michael Vigt (mvo) installed
```

By default, the `latest/stable` `jq` snap is on version `1.5+dfsg-1`, which is
the version you would obtain using the online SaaS Store. In this case, the
override changes the version to that of revision 11, which is `1.6`, and that is
the version **test-device** should downloaded from the **test-store**. 

## Cleaning up

To revert the override, refresh to the current stable jq snap, and even remove the device from the Enterprise Store, there are a few steps to go through.

First, from within the **test-store**, delete the override:

```{terminal}
:user: root
:host: test-store
:copy:
:input: sudo enterprise-store delete-override jq stable
```

From the test-device, query the jq snap info again:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap info jq

... 

channels:
  latest/stable:    1.5+dfsg-1 2017-05-17  (6) 245kB -
  latest/candidate: 1.5+dfsg-1 2017-05-17  (6) 245kB -
  latest/beta:      1.6        2018-11-19 (11)   1MB -
  latest/edge:      1.6        2022-07-14 (19)   1MB -
installed:          1.5+dfsg-1             (6) 245kB -
```

Now, within the **test-device**, refresh the snap:

```{terminal}
:user: root
:host: test-device
:copy:
:input: sudo snap refresh jq

jq 1.5+dfsg-1 from Michael Vigt (mvo) refreshed
```

Finally, from within the **test-device**, we can disconnect the device from the store:

```{terminal}
:user: root
:host: test-device
:copy:
:input: sudo snap set core proxy.store=''
```

## Offline mode enablement

It's easy to enable offline mode on a device that has had the Enterprise Store installed and registered online.

From within your **test-store**, simply use the enable-airgap-mode command:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store enable-airgap-mode

:input: enterprise-store status
Store URL: http://test-store
Store DB: ok
Store is in device authenticated air-gapped mode
Store ID: <STORE_ID>

...
```

## Offline Enterprise Store setup

Now we're going to use the **test-offline-store** to deploy a new Enterprise Store, while that container is effectively completely offline.

From your **host machine** we can use `iptables` to isolate our LXC containers:

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

See the {ref}`cleanup` section on how to revert this setting.
```

Next, you need to obtain some software online, and transfer it to your test-offline-store. We will do this by using the host machine to download the required files, and then push the files to the store with `lxc file push`.

On your **host machine**, download PostgreSQL:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo snap download postgresql

Fetching snap "postgresql"
Fetching assertions for "postgresql"
Install the snap with:
   snap ack postgresql_62.assert
   snap install postgresql_62.snap
```

Then push the downloaded files to your **test-offline-store**:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo lxc file push postgresql_62.* test-offline-store/root/
```

To obtain a functional Enterprise Store for installation offline requires registering it while online. This is something done by using the `store-admin` snap and specifically registering an offline store.

On your **host machine**, install the `store-admin` snap: 

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo snap install store-admin
```

Then register an offline store with the domain to be used offline:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: store-admin register --offline http://test-offline-store
```

```{note}
You may be prompted to open a browser and verify your Ubuntu One account.
```

This will produce a tarball for installation on an offline host. Push that tarball to your **test-offline-store** container:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: lxc file push offline-snap-store.tar.gz test-offline-store/root/
```

In **test-offine-store**, install PostgreSQL: 

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: snap ack /root/postgresql_62.assert

:input: snap install /root/postgresql_62.snap
```

In **test-offline-store**, install the store:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: tar -xvzf offline-snap-store.tar.gz

:input: cd offline-snap-store


```{terminal}
:user: root
:host: test-offline-store
:dir: offline-snap-store
:copy:
:input: sudo ./install.sh

:input: enterprise-store status 
```

Next, set the domain of your Enterprise Store:

```{terminal}
:user: root
:host: test-offline-store
:copy:
:input: enterprise-store config proxy.domain="test-offline-store"
```

Then, configure PostgreSQL for use with the Enterprise Store:

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
EOF
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

The Enterprise Store should now be fully set up and configured.

## Sideloading a snap

To sideload a snap into an air-gapped Enterprise Store, you need to use an online device with the store-admin snap installed to export the snap, move it to your air-gapped device, then import it into the store.

We'll use your **host machine** to export two snaps, transfer them to **test-offline-store**, and simulate an air-gapped device downloading the snaps from the air-gapped Enterprise Store.

On your **host machine**, use `store-admin` to export the `helix` and `htop` snaps:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: store-admin export snaps helix htop --channel=stable --arch=amd64 --arch=arm64 --export-dir .
```

Push the exported snaps to **test-offline-store**:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: lxc file push exported-snaps/* test-offline-store/root/
```

On the **test-offline-store**, push the snaps to the Enterprise Store:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: sudo enterprise-store push-snap /root/helix-20250820T050715.tar.gz
```

Check that the snaps have been successfully pushed to the store:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: sudo enterprise-store list-pushed-snaps
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
:input: curl -sL http://test-offline-store/v2/auth/store/assertions | sudo snap ack /dev/stdin

:input: snap known store
:input: sudo snap set core proxy.store=$(snap known store | grep "store:" | awk "{print $2}")
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
```

Check if `htop` is available:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: snap info htop
```

This will fail, as `htop` has not been pushed to the Enterprise Store.

Finally, install the `helix` snap to verify functionality:

```{terminal}
:user: root
:host: test-offline-device
:copy:
:input: snap install helix
```

(cleanup)=
## Cleanup

We've tried to keep the impact on your **host machine** minimal, but there are a couple of extra files and some LXC containers running that we should remove once we're done.

On your **host machine**, delete the firewall rules we created for offline testing:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo iptables -D FORWARD -i lxdbr0 -j REJECT

:input: sudo iptables -D FORWARD -i lxdbr0 -o lxdbr0 -j ACCEPT
```

And then delete folders and files we created for this tutorial:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: sudo lxc delete test-device --force

:input: sudo lxc delete test-offline-device --force
:input:sudo lxc delete test-store --force
:input: sudo lxc delete test-offline-store --force
```

And then delete folders and files we created:

```{terminal}
:user: user
:host: host
:dir: enterprise-store-tutorial
:copy:
:input: cd ../ && rm -r enterprise-store-tutorial
```

This should return your system to the state it was in before this tutorial.

## Next steps

Once you've completed this tutorial, you might be interested in how to implement {doc}`High Availability <how-to/high-availability>`, or {doc}`serve Charms <how-to/charmhub-proxy>` with your Enterprise Store.