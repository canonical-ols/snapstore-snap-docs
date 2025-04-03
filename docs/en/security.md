# Enhance Enterprise Store's security

## Enable HTTPS
TLS termination is not enabled by default. This means that the Enterprise Store
listens only on port 80 for plain text HTTP traffic after installation. If the
Enterprise Store was [registered](register.md) with an `--https` option, the
resulting [assertion](devices.md) instructing client devices to connect to the
Enterprise Store instead of the upstream store, is pointing those devices to use
HTTPS to connect to the Enterprise Store.

This section explains how to enable and configure TLS termination in the
Enterprise Store.

### Certificate and Key

Obtain an x509 key and certificate pair for your Enterprise Store domain (as
well as any relevant intermediate certificates if applicable). You can determine
the domain by running:

    snap-proxy config proxy.domain

This name will be the subject and should be one of the alternative names on the
certificate as well.

How to obtain the certificate/key pair is out of scope of this document.

### Importing the Key/Certificate pair

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

### Self signed certificates

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


### Next step

Once you've confirmed that your Enterprise Store is running and accepting HTTPS
connections, you can [configure client devices](devices.md) to use your
Enterprise Store.

At any time, you can use:

    snap-proxy status

to check the status of your Enterprise Store.


## Restrict network access

This section lists necessary network traffic requirements for the Enterprise
Store and example ways of restricting network access accordingly.

### Ingress traffic

The Enterprise Store only expects incoming traffic on port 443 when it is
configured to use HTTPS and port 80 when not.

To restrict access to the HTTPS port on the host machine itself on Ubuntu:

```
$ sudo ufw default deny incoming
$ sudo ufw allow in https
$ sudo ufw allow in ssh
$ sudo ufw enable
```

You might want to restrict ingress traffic to particular networks if needed.
Example:

```
$ sudo ufw allow in from 10.126.46.0/24 to any port https
```

The above allows also incoming traffic to port 22 (ssh) for general host
management access. The above ingress rules, or equivalent based on your firewall
setup of choice are sufficient for the Enterprise Store itself.

### Egress traffic

The Enterprise Store requires network access to the PostgreSQL database. To find
out the address of currently configured database:

```
$ snap-store-proxy config | grep db\.connection
proxy.db.connection: postgresql://snapproxy:<redacted>@10.126.46.135:5432/snapproxy
```

The result should contain the location of the database. In the example above it's
10.126.46.135. We can add a firewall rule to allow outgoing traffic to the database:

```
$ sudo ufw allow out from any to 10.126.46.135 port 5432
```

Note that by default, outgoing traffic is allowed by ``ufw``.

We can deny any other outgoing traffic from this host:

```
$ sudo ufw default deny outgoing
```

But this will impact its ability to:

- work correctly in the online mode
- and receive software updates.

So only do this when you've ensured that it can access the required resources.
For Enterprise Store online (default) mode
[network requirements](https://snapcraft.io/docs/network-requirements) apply.

Note that it's possible to configure the Enterprise Store to use an HTTP
forwarding proxy (like Squid) to proxy any outgoing HTTPS traffic.
Example:

```
$ sudo snap-store-proxy config proxy.https.proxy=http://squid.internal:3128
$ sudo ufw allow out from any to <squid IP address> 3128
```

By doing the above and configuring Squid to only allow traffic to the required
domains as noted in
[network requirements](https://snapcraft.io/docs/network-requirements), you can
limit the blast radius from potential vulnerabilities, if you also ensure that
it's only possible to talk to the outside world via that Squid proxy by
employing firewall rules.

#### Offline mode

In [offline](airgap.md) mode, the Enterprise Store only requires network access to:

1. Its configured PostgreSQL database.
1. Any external [device service](https://snapcraft.io/docs/the-gadget-snap) if
   it's needed. For example if you're using
   ``serial-vault-partners.canonical.com`` for device registration.
