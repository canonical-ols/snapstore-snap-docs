---
title: Offline Charmhub (air-gapped mode)
table_of_contents: true
---

# Offline Charmhub (air-gapped mode)

Version 2.30 (and above) of the Enterprise Store snap can also distribute charms and charm bundles in addition to snaps. Currently, this functionality is only available in offline mode, enabling the proxy to act as a local (on-premise) Charmhub.

This mode is particularly useful in network-restricted environments where external internet traffic is either not allowed or not possible.

The scope of this configuration is strictly limited to Charmhub-related activities, encompassing the management of charms, snaps, and their related resources. It does not cover the handling of other resources such as APT packages or any custom dependencies that a charm might require during runtime.

The Charmhub proxy does not incorporate an OCI registry. Users who work with Kubernetes charms must establish their own local OCI registry to manage container images.

## Offline Charmhub Configuration

Once the user has completed the [airgap installation](airgap.md#installation), the only remaining step is to configure the path to their local OCI registry. 

### Configure OCI registry

To configure your local OCI registry, specify a domain name or an IP. This setting should omit the protocol, requiring only the domain name itself.

In this setup, the local Charmhub does not directly access the registry; rather, it provides the image path and credentials to Juju. Juju then uses this information to instruct the container runtime to fetch the images.

The domain name and credentials are configured to override the default upstream domain and credentials, ensuring that charm OCI image paths are correctly served from your local setup.
```bash
sudo snap-store-proxy config proxy.oci-registry.domain=<registry-domain>
```
If required, set the credentials for registry access.
```bash
sudo snap-store-proxy config proxy.oci-registry.username=some-username proxy.oci-registry.password=some-password
```

## Export packages

On an internet-connected machine, export the required charms and resources as illustrated in the following sections, then copy the exported files to the air-gapped Charmhub Proxy host (or registry host for OCI images).

### Export charm bundles

If the offline deployment target is a [Charmhub bundle](https://charmhub.io/?type=bundle), then the bundle and its component charms can be exported like so:

```bash
$ store-admin export bundle cos-lite --channel=latest/stable --series=kubernetes --arch=amd64
Downloading cos-lite revision 11 (stable)
  [####################################]  100%
Downloading traefik-k8s revision 176 (stable)
...
...
Successfully exported charm bundle cos-lite: /home/ubuntu/snap/store-admin/common/export/cos-lite-20240426T143758.tar.gz
```

If not specified, `channel` defaults to `<default-track>/stable`, `series` defaults to `jammy`, and `arch` defaults to `amd64`. If a charm is not found for a given Ubuntu series, the exporter will attempt to fallback or fall forward to the release available for the nearest LTS.

The component charms in the bundle will be auto-exported based on the channel and series defined in the bundle. If it is necessary to modify the bundle before exporting the component charms, then the `bundle.yaml` can be printed to `stdout` by passing `--only-print-yaml=True`.

### Export charms

To export individual charms, either start from an existing `bundle.yaml` or define one with a list of cherry-picked charms. The following shows an example for a custom-defined `charms.yaml` (can be any file name):

```yaml
applications:
  postgresql:
    charm: postgresql-k8s
    series: kubernetes
    channel: latest/stable
    resources:
      postgresql-image: postgres:local-image
  kafka:
    charm: kafka-k8s
```

The `charm` key is required, while the other fields will use default values if omitted. All extra keys will be ignored. The `resources` key is only necessary if a manual override of the OCI image subpath is required. See [Export OCI images](#export-oci-images) for use cases.

Pass the `charms.yaml` to the `export charms` command like so:

```bash
$ store-admin export charms ./charms.yaml
Overriding postgresql-image with local registry subpath.
Downloading postgresql-k8s revision 20 (latest/stable)
  [####################################]  100%
Downloading resources for postgresql-k8s
...
Successfully exported charms to: /home/ubuntu/snap/store-admin/common/export/charms-export-20240426T163115.tar.gz
```

The exported `tar.gz` contains the following:

```bash
charms-export-20240426T163115.tar.gz/
├─ bundle.yaml
├─ postgresql-k8s.tar.gz/
│  ├─ postgresql-k8s_20.charm
│  ├─ postgresql-k8s_publisher_account.assert
│  ├─ metadata.json
│  ├─ resources/
│  │  ├─ postgresql-k8s.postgresql-image_19
```

where:

- `metadata.json` is the charm metadata fetched, this is required by CHP to write the charm's channel map and other metadata to enable deployments.
- `bundle.yaml` is a copy of the user-specified export `.yaml`, provided for ease of reference.
- `postgresql-k8s_20.charm` is the binary downloaded from Charmhub, for the revision resolved.
- `postgresql-k8s_publisher_account.assert` is the account assertion of the charm publisher.
- `resources/` contain resource binaries attached to the exported charm revision.

### Export snap resources

Some charms may require a specific snap revision as a resource. These charms usually run the equivalent of `snap install <snap> --revision <rev>` in their setup code ([example](https://github.com/canonical/postgresql-operator/blob/9614915048ba612bb4be6a5fd8c752a46bb051ed/lib/charms/operator_libs_linux/v2/snap.py#L460)).
To export snaps by revision, define a `.yaml` file of the following structure:

```yaml
packages:
  - name: charmed-postgresql
    revision: 96
    push_channel: chp_14/edge
  - name: charmed-mysql
    revision: 97
    push_channel: 8.0/edge
```

When installing a snap by revision, the Snap Store requires that the revision exists in the snap's channel map history, i.e. the revision must have been released to any channel before it can be requested directly. Thus, `push_channel` needs to be specified to tell Enterprise Store the target channel for the revision. This can be a channel that exists for the snap, thereby effectively overriding the channel when the snap is pushed, or it can be an arbitrary track, which would be created in the proxy on push.

The export `.yaml` can be supplied to the `export snaps` command like so:

```bash
$ store-admin export snaps --from-yaml snaps.yaml
Downloading charmed-postgresql revision 96 (chp_14/edge amd64)
  [####################################]  100%
Downloading charmed-mysql revision 97 (8.0/edge amd64)
  [####################################]  100%
Successfully exported snaps:
charmed-postgresql: /home/ubuntu/snap/store-admin/common/export/charmed-postgresql-20240429T122503.tar.gz
charmed-mysql: /home/ubuntu/snap/store-admin/common/export/charmed-mysql-20240429T122503.tar.gz
```

### Export OCI images

A local OCI registry needs to be set up to enable charms with OCI image resources. On charm export, the OCI image metadata blob is written to the `resources` directory, e.g. for `postgresql-k8s`:

```json
{
  "ImageName": "registry.jujucharms.com/charm/kotcfrohea62xreenq1q75n1lyspke0qkurhk/postgresql-image@sha256:8a72e1152d4a01cd9f469...",
  "Password": "MDAxOGxvY2F0aW9uIGNoYXJtc3Rvcm...",
  "Username": "docker-registry"
}
```

The image itself needs to be exported using a separate tool such as `skopeo`, which can transfer images between registries, and between a registry and a local directory, while preserving the image hash.

For example, to save the above image to a local directory:

```bash
$ skopeo copy docker://registry.jujucharms.com/charm/kotcfrohea62xreenq1q75n1lyspke0qkurhk/postgresql-image@sha256:8a72e1152d4a0... --src-creds=docker-registry:MDAxOGxvY2F0aW9... dir:/home/ubuntu/<target-dir>
```

The directory can then be manually copied to the air-gapped registry host, then pushed to the registry like so:

```bash
$ skopeo copy dir:/home/ubuntu/<copied-dir> docker://<local-registry-domain>/charm/kotcfrohea62xreenq1q75n1lyspke0qkurhk/postgresql-image@sha256:8a72e1152d4a0... --dest-creds=<local-registry-username>:<local-registry-password>
```

By default, if no override is supplied via the `resources` key in the `.yaml` supplied for charm export, Charmhub Proxy will assume an identical local registry image path (excluding the domain but including `charm/` and including the sha256 tag). When a deployment is requested, CHP will supply a regenerated blob using the local domain URL and credentials configured.

The `skopeo` commands above pushes the image to the same path in the local registry and saves the effort of manually remapping resources. If required, the image can be pushed to a custom path, but a mapping must be defined for the resource as in the example `charms.yaml` in [Export charms](#export-charms).

## Import Packages
Once the exported charm tar file is on the on-prem store host, they should be moved to the
`/var/snap/snap-store-proxy/common/charms-to-push/` directory, from where they
can be imported.

Example of importing `charms-export-20240429T090849.tar.gz` from the previous example:

```bash
sudo snap-store-proxy push-charms /var/snap/snap-store-proxy/common/charms-to-push/charms-export-20240429T090849.tar.gz
```

Example of importing a `cos-lite` bundle:

```bash
sudo snap-store-proxy push-charm-bundle /var/snap/snap-store-proxy/common/charms-to-push/cos-lite-20240401T172030.tar.gz
```

When re-importing charms or importing other revisions, make sure to provide the `--push-channel-map`.


After importing, the charms/bundles are then available to be managed with Juju commands.  

- When importing machine charms that depend on a snap for functionality, you must first manually [import the required snap](airgap.md#side-loading-snaps).
- When importing Kubernetes charms, ensure that the corresponding OCI image is copied to the local registry, maintaining its original path.


## Configure Juju 

Ensure you have Juju configured along with the necessary cloud environment. 

For production environments, particularly if you need self-signed TLS certificates to function correctly, set up the Juju controller on a non-Kubernetes instance.
Even if the Juju controller isn't hosted on a Kubernetes cluster, it can still manage Kubernetes models. This flexibility allows the controller to operate from a different environment, such as a virtual machine or an LXD container, while still effectively orchestrating resources within Kubernetes.


This setup allows you to incorporate a self-signed certificate within the `cloudinit` configuration, enabling the Juju controller to trust the certificate.


First, you need to prepare the Juju configuration file. In this file, override the default URLs for Charmhub and Snap Store. Additionally, if you're using a self-signed certificate for Charmhub, include it in the trusted certificates section of `cloudinit-userdata`. 

### Self-signed certificate


You can create a self signed certificate for the Enterprise Store with the following command:
```bash
sudo snap-store-proxy import-certificate --selfsigned
```

After it's created, you can retrieve the public key from the configuration:
```bash
snap-store-proxy config proxy.tls.cert | cat > tls-cert.crt
```
When using a self-signed certificate, it’s crucial to ensure that the underlying operating system where the Juju client is running trusts the certificate. You can achieve this by adding the certificate to the system's trusted store. 
You can achieve that with the following commands:
```bash
sudo cp your_certificate.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### Configuration file

Example of a Juju configuration `.yaml`. Note that ca-certs list is necessary only when using self-signed certificate for the local Charmhub.
```yaml
cloudinit-userdata: |
  ca-certs:
    trusted: 
    - |
      -----BEGIN CERTIFICATE-----
      MIIFGjCCAwKgAwIBAgIUQzfvzTdygyQdNx69x/sMzu/xWF4wDQYJKoZIhvcNAQEL
      ...
      mfV/T8n8J15gfYTAyKs=
      -----END CERTIFICATE-----
charmhub-url: https://local-charmhub.internal
snap-store-proxy-url: https://local-charmhub.internal
```
Store this file in a Juju accessible path e.g. `/var/snap/juju/common/juju-config.yaml`.

### Controller and Model setup

After configuring the certificate, the next steps depend on your deployment target. If you plan to deploy to a Kubernetes (k8s) cloud, you'll need to add the substrate to this controller to facilitate the deployment. However, if you're deploying machine charms, this additional step is not necessary.

```bash
juju bootstrap lxd machine-controller --config=/var/snap/juju/common/juju-config.yaml
```


The example below assumes that an LXD cloud is already set up and utilises it to create a Juju controller:
```bash
juju add-k8s k8s-cloud --controller=machine-controller 
```

We can then create a model using the following example:
```bash
juju add-model test-model k8s-cloud --config /var/snap/juju/common/juju-config.yaml 
```

In case we want to deploy to a non k8s cloud, we can skip the cloud parameter:
```bash
juju add-model test-model --config /var/snap/juju/common/juju-config.yaml 
```

### Deploy

Finally, we can deploy the charms using the standard Juju command.

```bash
juju deploy cos-lite
```

All charm management commands associated with the controller, including `refresh` and `remove`, work seamlessly out of the box.

### Info commands

Some Juju commands are not tied to a controller and instead require the setup of an environment variable. Notably, this includes the `info` and `download` commands. In such cases, you can set the `CHARMHUB_URL` environment variable before executing these commands. 

```bash
CHARMHUB_URL="https://local-charmhub.internal" juju info cos-lite
```
To make this change more permanent, you can add the variable to the `.bashrc` file in the user's home folder. 

This ensures that the custom URL is consistently used whenever [Juju commands](https://juju.is/docs/juju/manage-charms-or-bundles) are run from the terminal.

