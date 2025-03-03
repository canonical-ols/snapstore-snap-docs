# Cryptography

Various Cryptographic technologies are used to enable secure Enterprise Store operation.
Below are the functionalities of the Enterprise Store that use cryptographic technologies,
and the details of the cryptographic technologies used.

- **Signing assertions**: the Enterprise Store signs various
[assertions](https://ubuntu.com/core/docs/reference/assertions).
The key ID of the signing key is encoded with SHA3-384, and the assertion is signed with RSA.

- **Hash of artefacts**: the Enterprise Store generates many hashes of an uploaded artefact
using SHA3-384, SHA256 and SHA512 to ensure the uniqueness and integrity of the artefact.

- **OCI charm resources credentials**: an OCI runtime
(e.g. [microk8s](https://microk8s.io/docs)) must authenticate against the Enterprise Store
in order to download the OCI [charm resources](https://juju.is/docs/juju/charm-resource).
The credentials are encoded as JWT that are signed with RSA.

- **Signing nonce**: A nonce is used as additional security for REST API access.
RSA is used to sign and verify the nonce.


| Function                     | Exposed | Technology               | Package/Library                                                                                                                                                                  |
|---------------------------------|---------|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Signing assertions              | Yes     | SHA3-384, RSA 4096/8192  | [snapd](https://github.com/canonical/snapd), [lp-signing](https://launchpad.net/lp-signing)                                                                                      |
| Hash of artefacts               | Yes     | SHA3-384, SHA256, SHA512 | [review-tools](https://launchpad.net/review-tools)                                                                                                                               |
| OCI charm resources credentials | Yes     | RSA 4096, JWT            | [cryptography](https://github.com/pyca/cryptography), [pyjwt](https://github.com/jpadilla/pyjwt), [py-macaroon-bakery](https://github.com/go-macaroon-bakery/py-macaroon-bakery) |
| Signing nonce                   | Yes     | RSA 4096                 | [cryptography](https://github.com/pyca/cryptography), [pem](https://github.com/hynek/pem)                                                                                        |
