# Getting started with the store

In this tutorial, we will set up and test the Enterprise Store in an online
environment. We will cover how to set the store up, how
to make specific snaps available from the store, and how to obtain those snaps
on a connected device.

Once you've completed this tutorial, you should be able to set the Enterprise
Store up in your own environment, connect your devices to it, and be able to use
it to control snap revisions on any connected devices.

## Lesson plan

This tutorial will run through basic processes to set up and utilise an
Enterprise Store. We will show you how to:

* Install the Enterprise Store in an online environment  
* Register your store  
* Pin a revision within the store  
* Connect a device to the store  
* Obtain a snap from the store in proxy mode

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

Launch two containers, **test-store**, and **test-device**:

```{terminal}
:user: user
:host: host
:copy:
:input: sudo lxc launch ubuntu:22.04 test-store

:input: sudo lxc launch ubuntu:22.04 test-device
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

## Enterprise Store installation

Within the **test-store** container, install the Enterprise Store snap and verify the installation:

```{terminal}
:user: root
:host: test-store
:copy:
:input: snap install enterprise-store

:input: snap list enterprise-store
```

Next, configure the domain for Enterprise Store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: hostname

test-store

:input: enterprise-store config proxy.domain="test-store" 
proxy.domain: test-store
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
:input: snap install postgresql
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
```

Save the file with **ctrl + x** and press **y** and then **enter** when prompted.

Run configure and start the postgres instance:

```{terminal}
:user: root
:host: test-store
:copy:
:scroll:
:input: cp ~/proxydb.sql /var/snap/postgresql/common/

:input: snap run postgresql.psql -U postgres -f /var/snap/postgresql/common/proxydb.sql
```

Configure the Enterprise Store to use the database.

```{terminal}
:user: root
:host: test-store
:copy:
:scroll:
:input: enterprise-store config proxy.db.connection="postgresql://snapproxy-user@localhost:5432/snapproxy-db?sslmode=disable"

Authentication error with user snapproxy-user.

Check the user name and password and that the user has the LOGIN privilege.

Please enter password for database user snapproxy-user (attempt 1 of 3):
```

Enter `snapproxy-password`, then check that the postgres instance has started successfully:

```{terminal}
:user: root
:host: test-store
:copy:
:scroll:
:input: snap services postgresql

:input: snap run postgresql.psql -U postgres -d snapproxy-db
```

This will open the postgres database. Return to the store CLI with `quit`:
```{terminal}
:user: snapproxy-db
:host: 
:copy:
:scroll:
:input: quit
```

Finally, check the store's connections:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store check-connections

http: https://dashboard.snapcraft.io: OK 
http: https://login.ubuntu.com: OK 
http: https://api.snapcraft.io: OK 
postgres: localhost: OK 
All connections appear to be accessible
```

You should now have the Enterprise Store installed, a valid domain provided by LXD, and a database configured for your store.

## Enterprise Store registration

Within the **test-store** container, register your Enterprise Store:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store register
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
:input: curl -sL http://test-store/v2/auth/store/assertions | snap ack /dev/stdin
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
:input: snap set core proxy.store=$(snap known store | awk '/store:/{print $2}')
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

jq stable amd64 11
```

Ensure the override is set properly:

```{terminal}
:user: root
:host: test-store
:copy:
:input: enterprise-store list-overrides jq

jq stable amd64 11 (upstream 6)
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
:input: enterprise-store delete-override jq stable
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
:input: snap refresh jq

jq 1.5+dfsg-1 from Michael Vigt (mvo) refreshed
```

Finally, from within the **test-device**, we can disconnect the device from the store:

```{terminal}
:user: root
:host: test-device
:copy:
:input: snap set core proxy.store=''
```

(cleanup)=
## Cleanup

This tutorial has deployed a couple of LXC containers on your **host machine**.
Make sure you remove them:

```{terminal}
:user: user
:host: host
:dir: 
:copy:
:input: sudo lxc delete test-device --force

:input: sudo lxc delete test-store --force
```

This should return your system to the state it was in before this tutorial.

## Next steps

Once you've completed this tutorial, you may want to try the tutorial for an
{doc}`air-gapped Enterprise Store deployment <air-gapped-deployment>`.
