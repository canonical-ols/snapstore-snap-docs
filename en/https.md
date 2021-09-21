---
title: HTTPS
table_of_contents: true
---

# HTTPS

TLS termination is not enabled by default. This means that the proxy listens
only on port 80 after installation. If the proxy was [registered](register.md)
with an `--https` option, the resulting [assertion](devices.md) instructing
client devices to connect to the proxy instead of the upstream store is pointing
those devices to use HTTPS to connect to the proxy.

This document explains how to enable and configure TLS termination in the Snap
Store Proxy.

## Certificate and Key

Obtain an x509 key and certificate pair for your Snap Store Proxy domain. You can
determine the domain by running:

    snap-proxy config proxy.domain

This name will be the subject and/or one of the alternative names on the
certificate.

How to obtain the certificate/key pair is out of scope of this document.

## Importing the Key/Certificate pair

Running the below command will import the key/certificate pair and re-configure
your Snap Store Proxy:

    cat my.cert my.key | sudo snap-proxy import-certificate

After this is done, TLS termination will be enabled, and any HTTP traffic to
your Snap Store Proxy will be redirected to HTTPS.

## Self signed certificates

The TLS certificate above may be self signed or issued by a certificate
authority that is not included in the system certificate store on your snap
devices. If this is true, then you need to make sure that the certificates in
question are added to the system certificate store on those devices. On Ubuntu
devices this might be achieved by placing the certificate in question in a
specific directory:

    sudo cp selfsigned.crt /usr/local/share/ca-certificates/

then running:

    sudo update-ca-certificates

and finally, `snapd` has to be restarted.

    sudo systemctl restart snapd

After that, snapd will be able to successfully verify the certificate.

## Next step

Once you've confirmed that your Snap Store Proxy is running and accepting HTTPS
connections, you can [configure client devices](devices.md) to use your Snap
Store Proxy.

At any time, you can use:

    snap-proxy status

to check the status of your Snap Store Proxy.
