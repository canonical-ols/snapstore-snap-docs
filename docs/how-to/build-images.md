---
title: Build Ubuntu Core images from your store
table_of_contents: true
description: Build Ubuntu Core images from an air-gapped Enterprise Store using ubuntu-image with Dedicated Snap Store credentials.
---

# Build Ubuntu Core images from your store

```{warning}
This functionality requires a [Dedicated Snap Store](https://ubuntu.com/internet-of-things/appstore), also known as an IoT App Store.
```

Ubuntu Core image building from an air-gapped Enterprise Store requires passing
extra options in the form of environment variables to `ubuntu-image`, including:

* The URL of the Enterprise Store
* Dedicated Snap Store credentials
* The Dedicated Snap Store ID

```{terminal}
:user: user
:host: admin-box

export UBUNTU_STORE_URL="https://snaps.acme.internal"
export UBUNTU_STORE_AUTH="$(cat acme-onprem-credentials)"
export UBUNTU_STORE_ID="StoreIdXYZ"
ubuntu-image classic acme-core20-amd64.model
```

```{note}
The `UBUNTU_STORE_ID` is only required for classic images.
```

See the [Ubuntu Core documentation](https://documentation.ubuntu.com/core/)
for more information on Ubuntu Core.