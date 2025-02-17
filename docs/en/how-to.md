---
title: Enterprise Store How-to guides
---

# Enterprise Store How-to guides

If you have a specific goal, but are already familiar with the Enterprise Store,
our *How-to* guides have more in-depth detail than our tutorials and can be applied to
a broader set of applications. They’ll help you achieve an end result but may require
you to understand and adapt the steps to fit your specific requirements.



| **How-to guides**                         | Get stuff done                                                        |
|-------------------------------------------|-----------------------------------------------------------------------|
| [Installation](install.md)                | Install and set up the Enterprise Store                               |
| [Proxy registration](register.md)         | Register the Proxy with the online Snap Store                         |
| [TLS configuration](https.md)             | Configure TLS termination in the Proxy                                |
| [Configuring snap devices](devices.md)    | Point your devices to the Proxy instead of the online Snap Store      |
| [Overriding snap revisions](overrides.md) | Control the specific revision of a snap in a channel for your devices |
| [Offline store](airgap.md)                | Deploy the Proxy in an air-gapped environment                         |
| [Model service](on-prem-model-service.md) | Configure an air-gapped Proxy for signing device serial requests      |
| [Troubleshooting](trouble.md)             | Check Proxy configuration status and diagnose common issues           |

Alternatively, our *Tutorials* section contain step-by-step tutorials to help outline
what the Proxy is capable of while helping you achieve specific aims.

Take a look at our *Reference* section for technical details (such as the Overrides API
specs and authentication mechanism), and other supplementary reference materials.

Finally, for a better understanding of how the Enterprise Store works, our *Explanation*
section enables you to expand your knowledge.

```{eval-rst}
.. toctree::
    :hidden:
    :maxdepth: 1

    Install an Enterprise Store <install>
    Register an Enterprise Store <register>
    Configure HTTPS <https>
    Configure devices <devices> 
    Override snap revisions <overrides>
    Operate offline <airgap>
    Configure the Model Service <on-prem-model-service>
    Manage charms in the Enterprise Store <charmhub-proxy>
    Troubleshoot common issues <trouble>
```