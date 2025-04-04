---
title: Charmhub Proxy
table_of_contents: true
---

# Charmhub Proxy

Version 3.0 (and above) of the Enterprise Store snap is able to serve Charms and Charm Bundles in air-gapped Juju deployments. We refer to these functionalities as the Charmhub Proxy (CHP). The overall workflow is similar to that for the [offline snap store](airgap.md): export, push, then deploy.

## Setup

Follow the steps in the [Installation](airgap.md#installation) section to register an offline store and pack an offline store installation bundle.

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
To export snaps by revision, define a .`yaml` file of the following structure:

```yaml
packages:
  - name: charmed-postgresql
    revision: 96
    push_channel: chp_14/edge
  - name: charmed-mysql
    revision: 97
    push_channel: 8.0/edge
```

The Snap Store implementation of snap installs by revision requires that the revision exists in the snap's channel map history, i.e. the revision must have been released to any channel before it can be requested directly. Thus, `push_channel` needs to be specified to tell Enterprise Store the target channel for the revision. This can be a channel that exists for the snap, thereby effectively overriding the channel when the snap is pushed, or it can be an arbitrary track, which would be created in the Proxy on push.

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

```{eval-rst}
.. toctree::
    :maxdepth: 1

    Operate charms offline <airgap-charmhub>
```