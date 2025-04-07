---
title: Register
table_of_contents: true
---

# Registration

## Initial registration

To register the proxy, you will need to provide Ubuntu SSO credentials
for the desired account you wish to link the proxy with, and answer
some simple questions about your deployment:

    sudo enterprise-store register --https

or:

    sudo enterprise-store register

If the `--https` option is omitted, the resulting [assertion](devices.md)
instructing client devices to use the proxy instead of the upstream store, will
instruct them to use HTTP to connect to the proxy instead of HTTPS.

You can examine your proxy's registration status with:

    enterprise-store status

This will show the registration status of your proxy, as well as local
status information of this server.

At this point, your proxy will be assigned a Store ID, which can be retrieved
with the status command. This will be used in later commands and to
identify your proxy for support purposes.

After successful registration it's advised to securely store the private key
generated during the process. This key is your proxy's identity. The key
pair can be viewed using:

    sudo enterprise-store config proxy.key.public proxy.key.private


## Next step

Configure the proxy to [serve HTTPS](security.md) traffic if `--https`
registration option was used, or proceed to [configure client
devices](devices.md).
