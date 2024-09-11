---
title: Cryptography
table_of_contents: true
---

# Cryptography

Various Cryptographic technologies are used to enable secure Snap Store Proxy operation.
Below is an outline of the various functions that use cryptographic technologies,
and the details of the cryptographic technologies used.

| Function                     | Exposed | Technology               | Package/Library                                                                                                                                                                  |
|------------------------------|---------|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Signing assertions           | Yes     | SHA3-384, RSA 4096/8192  | [snapd](https://github.com/canonical/snapd), [lp-signing](https://launchpad.net/lp-signing)                                                                                      |
| Hash of artefacts            | Yes     | SHA3-384, SHA256, SHA512 | [review-tools](https://launchpad.net/review-tools)                                                                                                                               |
| OCI charm resources password | Yes     | RSA 4096, JWT            | [cryptography](https://github.com/pyca/cryptography), [pyjwt](https://github.com/jpadilla/pyjwt), [py-macaroon-bakery](https://github.com/go-macaroon-bakery/py-macaroon-bakery) |
| Nonce signing                | Yes     | RSA 4096                 | [cryptography](https://github.com/pyca/cryptography), [pem](https://github.com/hynek/pem)                                                                                        |
