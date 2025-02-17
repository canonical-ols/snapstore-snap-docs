---
title: On-prem model service
table_of_contents: true
---

# On-Prem Model Service

The Snap Store's Model Service is the device serial provisioning service that is intended to supersede the [Serial Vault](https://ubuntu.com/core/services/guide/serial-vault-overview). While the Serial Vault had to be deployed separately in on-prem scenarios, the Model Service is packaged into the Enterprise Store.

The Model Service is currently only available in [air-gapped](airgap.md) mode. When operating in online mode, the Proxy can forward serial requests made by devices to the online Serial Vault or the online Model Service.

The following requirements need to be met to use the on-prem Model Service:

- A PKCS#11-compatible Hardware Security Module (HSM) or Smart Card.
- The PKCS#11 module / shared library for the hardware. e.g. `opensc-pkcs11.so`
- The Enterprise Store host machine must run Ubuntu 22.04 (Jammy) with the `p11-kit` and `gnutls-bin` packages installed.
- Revision 99 of `snap-store-proxy` and revision 28 of `store-admin`, or newer.

The supported way to manage models, signing keys, and serial policies in the on-prem Model Service is via the `store-admin` snap.

## HSM-based key management and signing

Currently, only PKCS#11-compatible hardware can be used for key generation and signing device serial requests. Software key generation and signing are not supported, with the exception of using a software PKCS#11 emulator such as [SoftHSMv2](https://github.com/opendnssec/SoftHSMv2).

[p11-kit](https://p11-glue.github.io/p11-glue/p11-kit.html) is used as an abstraction layer for hardware-agnostic PKCS#11 support.

## Setup

This section assumes that the Enterprise Store has been installed and configured in air-gapped mode and that the Brand Store has been imported, as per the installation steps in the [Offline store section](airgap.md#installation). On Brand Store import, the Brand account and admin user will be automatically set up in the Model Service.

### Store admin token

To login using `store-admin` to the Model Service, set the `STORE_ADMIN_TOKEN` environment variable, obtained after running `store-admin export store`:

```bash
$ store-admin export store myDeviceViewStoreID --key <model-assertion-account-key-sha3-384>

...

Creating the export archive...
Store data exported to: /home/ubuntu/snap/store-admin/common/export/store-export-myDeviceViewStoreID-20240109T123041.tar.gz
Admin token exported to: /home/ubuntu/snap/store-admin/common/export/store-export-myDeviceViewStoreID-20240109T123041.macaroon
Admin token usage:
    export STORE_ADMIN_TOKEN=$(cat /home/ubuntu/snap/store-admin/common/export/store-export-myDeviceViewStoreID-20240109T123041.macaroon)
```

As outlined in the [air-gapped store setup instructions](airgap.md#brand-store-export), the account-key assertion for the key(s) used to [sign the model assertion(s)](https://ubuntu.com/core/docs/sign-model-assertion) must also be exported and pushed to the Proxy. Include them in the store export bundle by specifying the `--key` flag for each account-key SHA3-384.

[Import the store bundle on the Proxy](airgap.md#brand-store-import), then login to the air-gapped store from the admin machine:

```bash
$ store-admin login --offline <http-location-of-the-store> <same-email-as-in-export-store>

Exchanging store admin macaroon for a publisher gateway admin macaroon...
```

Access via the `store-admin` snap should now be set up for the Model Service.

### p11-kit server

**On the Proxy host**, start the p11-kit server.

Obtain the `pkcs11:` identifier using `p11tool`, e.g.:

```bash
$ p11tool --provider "/usr/lib/x86_64-linux-gnu/opensc-pkcs11.so" --list-token-urls | sed 's/;token=.*//g'

pkcs11:model=PKCS%2315%20emulated;manufacturer=www.CardContact.de;serial=DENK0300972
```

Start the server, ensuring that the Unix socket runs under `/var/snap/snap-store-proxy/common/pkcs11`. See the p11-kit [documentation](https://p11-glue.github.io/p11-glue/p11-kit/manual/) for other configuration options.

```bash
$ sudo p11-kit server --provider /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so "pkcs11:model=PKCS%2315%20emulated;manufacturer=www.CardContact.de;serial=DENK0300972" -n "/var/snap/snap-store-proxy/common/pkcs11" -f

P11_KIT_SERVER_ADDRESS=unix:path=/var/snap/snap-store-proxy/common/pkcs11; export P11_KIT_SERVER_ADDRESS;
P11_KIT_SERVER_PID=26963; export P11_KIT_SERVER_PID;
```

Restart the Model Service (this needs to be done each time the p11-kit server is restarted):

```bash
snap restart snap-store-proxy.snapmodels
```

### Enterprise Store configuration

Set the HSM label and pin in the Proxy snap:

```bash
$ p11tool --list-tokens

Token 0:
    Label: SmartCard-HSM (UserPIN)
...

$ sudo snap-proxy config proxy.hsm.token-label="SmartCard-HSM (UserPIN)"

$ sudo snap-proxy config proxy.hsm.token-pin=74656
```

## Model Service CLI Usage

The Model Service management CLI is provided by the `store-admin` snap.

### Create a signing key on the HSM

Create a signing key using `store-admin` for signing serial requests:

```
$ BRAND_ACCOUNT_ID=<brand-account-id> store-admin create key test-key
Generating a signing keypair on the proxy's HSM. This may take some time.
Signing key 'test-key' created.

$ store-admin list keys
Name      SHA3-384
--------  ----------------------------------------------------------------
test-key  PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see
```

The `BRAND_ACCOUNT_ID` environment variable only needs to be set once; it will be stored and automatically used subsequently.

```{note}
If a 4096-bit RSA key takes more than 15 seconds to generate on your hardware
(e.g. Nitrokeys), then you would first have to extend the Proxy's internal service timeout:
`sudo snap-store-proxy config internal.publishergw.snapmodels.read-timeout={timeout-in-seconds}`
```

The key needs to be registered with the online Snap Store before it can sign serials:

```bash
$ store-admin register-key PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see
Registering signing key with the global Snap Store...
...

Key PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see registered.
```

The account-key assertion needs to be pushed to the air-gapped Proxy. First, export the assertion:

```bash
snap known --remote account-key public-key-sha3-384=PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see > test-key.assert
```

Copy the assertion to the Enterprise Store's `$SNAP_COMMON` directory on the Proxy host, then push the assertion to the Proxy:

```bash
sudo snap-proxy push-account-keys /var/snap/snap-store-proxy/common/test-key.assert
```

```{note}
Repeat these steps to add new account-keys to the proxy, if any are created after the initial store import and are used to sign new model assertions.
```

### Add a model in the Model Service

To sign the serial requests for devices of a model, the model name as configured in the Model Service must match that in the model assertion:

```bash
$ store-admin create model model-a
API key (alphanumeric, `pwgen 40` for options): model-a-apikey
Model 'model-a' created.
```

### Configure a serial signing policy

The serial policy for a model identifies the signing key that the Model Service should use to sign serial requests for that model. To configure the Model Service to sign `model-a` device serial requests with the earlier-created `test-key`:

```bash
$ store-admin create serial-policy
Model to attach the serial signing policy: model-a
Signing key to use (SHA3-384): PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see
Model 'model-a' configured to sign serials with key 'PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see'.

$ store-admin list models
Name     API key         Active serial signing key
-------  --------------  ---------------------------
model-a  model-a-apikey  test-key
```

The key can be changed by creating a new serial policy revision for the model:

```bash
$ store-admin create key new-key
...

$ store-admin list keys
Name      SHA3-384
--------  ----------------------------------------------------------------
test-key  PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see
new-key   4aPBeXLPu2xoriNr-6e1Ja448wC7IAS86Ijs6r0sHWiZ6Y9WYprxeWkK7HETCyh6

$ store-admin create serial-policy
Model to attach the serial signing policy: model-a
Signing key to use (SHA3-384): 4aPBeXLPu2xoriNr-6e1Ja448wC7IAS86Ijs6r0sHWiZ6Y9WYprxeWkK7HETCyh6
Model 'model-a' configured to sign serials with key '4aPBeXLPu2xoriNr-6e1Ja448wC7IAS86Ijs6r0sHWiZ6Y9WYprxeWkK7HETCyh6'.

$ store-admin list models
Name     API key         Active serial signing key
-------  --------------  ---------------------------
model-a  model-a-apikey  new-key
```

## Device gadget snap

The `prepare-device` hook in the device [gadget](https://ubuntu.com/core/docs/gadget-snaps#heading--example-prepare) snap should be configured with the proxy host URL and the model API key defined in the Proxy Model Service.

On first startup, a `model-a` device should request and obtain a serial assertion from the Enterprise Store:

```bash
$ snap model --serial --assertion

type: serial
...
model: model-a
...
sign-key-sha3-384: PPkB6XcYjkxzA9c6dXsaM0sg9r_d5DZ2kDYvWPTeuSXofXGzMDBt7DoD_Xiw3see
...
```
