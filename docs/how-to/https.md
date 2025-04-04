---
title: HTTPS
table_of_contents: true
---

# HTTPS

TLS termination is not enabled by default. This means that the proxy listens
only on port 80 after installation. If the proxy was [registered](register.md)
with an `--https` option, the resulting [assertion](devices.md) instructing
client devices to connect to the proxy instead of the upstream store, is pointing
those devices to use HTTPS to connect to the proxy.

This document explains how to enable and configure TLS termination in the
Enterprise Store.

## Certificate and Key

Obtain an x509 key and certificate pair for your Enterprise Store domain (as
well as any relevant intermediate certificates if applicable). You can determine
the domain by running:

    snap-proxy config proxy.domain

This name will be the subject and should be one of the alternative names on the
certificate as well.

How to obtain the certificate/key pair is out of scope of this document.

## Importing the Key/Certificate pair

Running the below command will import the key/certificate pair (and any
intermediate certificates as needed) and re-configure your Enterprise Store:

    cat my.cert my.key [intermediate.cert ...]  | sudo snap-proxy import-certificate

For example when configuring a Let's Encrypt issued certificate, you'd want to
include the key, the certificate and intermediate certificates. Since Let's
Encrypt provides `fullchain.pem` that includes both the site and intermediate
certificates, you can use:

    cat fullchain.pem my.key | sudo snap-proxy import-certificate

After this is done, TLS termination will be enabled, and any HTTP traffic to
your Enterprise Store will be redirected to HTTPS. This command can be re-run as
needed.

## Self signed certificates

The TLS certificate above may be self signed or ultimately signed by a self
signed root CA that is not included in the system certificate store on your
client snap devices or the snap-store-proxy host itself. If this is true, then
you need to make sure that the self signed certificates in question are added
to:

* the system certificate store on the snap-store-proxy host,

* as well as its client devices.

On classic Ubuntu machines this might be achieved by placing the certificate in
question in a specific directory:

    sudo cp my-selfsigned-ca.crt /usr/local/share/ca-certificates/

(make sure that the certificate file extension is `.crt`) then running:

    sudo update-ca-certificates

If this is being done on the snap-store-proxy host, the snap-store-proxy has to be restarted:

    sudo snap restart snap-store-proxy

After that, snap-store-proxy will be able to verify its status correctly.

For client machines, `snapd` has to be restarted:

    sudo systemctl restart snapd

After that, `snapd` on the client device will be able to successfully verify the
snap-store-proxy certificate.

A more robust method of ensuring that client devices can talk to the
snap-store-proxy using a self signed certificate or one issued by a self signed
root is to configure the certificate in question using `snapd` itself:

    sudo snap set system store-certs.cert1="$(cat /path/to/my-cert-or-ca-cert.crt)"

The above method works both on classic systems as well as Ubuntu Core.


## Next step

Once you've confirmed that your Enterprise Store is running and accepting HTTPS
connections, you can [configure client devices](devices.md) to use your
Enterprise Store.

At any time, you can use:

    snap-proxy status

to check the status of your Enterprise Store.
