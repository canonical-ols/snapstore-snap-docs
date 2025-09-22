Store configuration
*******************

Enterprise Stores take a range of configuration for various purposes. These
values are set with ``enterprise-store config <KEY>=<Value>``.

..
    To be expanded later with additional help text.

Values
======

.. list-table::

    * - Key
      - Value

    * - proxy.domain
      - :code:`localhost`
        
    * - proxy.ipaddress
      - :code:`[::]`
        
    * - proxy.port.snapdevicegw
      - :code:`8000`
        
    * - proxy.port.snapident
      - :code:`8001`
        
    * - proxy.port.snaprevs
      - :code:`8002`
        
    * - proxy.port.snapauth
      - :code:`8005`
        
    * - proxy.port.packagereview
      - :code:`8006`
        
    * - proxy.port.snapmodels
      - :code:`8007`
        
    * - proxy.port.publishergw
      - :code:`8010`
        
    * - proxy.port.snapstorage
      - :code:`8011`
        
    * - proxy.port.snapassert
      - :code:`5000`
        
    * - proxy.port.storeadmingw
      - :code:`8013`
        
    * - proxy.port.http
      - :code:`80`
        
    * - proxy.port.https
      - :code:`443`
        
    * - proxy.port.memcached
      - :code:`11211`
        
    * - proxy.upstream
      - :code:`https://api.snapcraft.io`
        
    * - proxy.trust-forwarded-proto
      - :code:`False`
        
    * - proxy.auth.secret
      - :code:`None`
        
    * - proxy.device-auth.secret
      - :code:`None`
        
    * - proxy.device-auth.allowed-device-service-urls
      - :code:`["https://serial-vault-partners.canonical.com"]`
        
    * - proxy.hsm.token-label
      - None
        
    * - proxy.hsm.token-pin
      - None
        
    * - proxy.cache.size
      - :code:`2048`
        
    * - proxy.memcached.connection
      - None
        
    * - proxy.use-postgres-over-memcached
      - :code:`False`
        
    * - proxy.db.connection
      - :code:`None`
        
    * - proxy.dashboard.location
      - :code:`https://dashboard.snapcraft.io`
        
    * - proxy.sso.location
      - :code:`https://login.ubuntu.com`
        
    * - proxy.sso.public.key
      - :code:`<SSH-KEY>`
        
    * - proxy.tls.cert
      - :code:`None`
        
    * - proxy.tls.key
      - :code:`None`
        
    * - proxy.admin-emails
      - :code:`[]`
        
    * - proxy.key.private
      - :code:`None`
        
    * - proxy.key.public
      - :code:`None`
        
    * - proxy.https.proxy
      - None
        
    * - internal.store.id
      - :code:`None`
        
    * - internal.store.url
      - :code:`None`
        
    * - proxy.airgap
      - :code:`False`
        
    * - proxy.oci-registry.domain
      - :code:`registry.jujucharms.com`
        
    * - proxy.oci-registry.username
      - None
        
    * - proxy.oci-registry.password
      - None
        
    * - proxy.storage.backend
      - :code:`local`
        
    * - proxy.storage.s3.region
      - :code:`us-east-1`
        
    * - proxy.storage.s3.server-url
      - None
        
    * - proxy.storage.s3.use-path-style
      - :code:`True`
        
    * - proxy.storage.s3.access-key-id
      - None
        
    * - proxy.storage.s3.secret-access-key
      - None
        
    * - proxy.storage.s3.unscanned-container-name
      - :code:`unscanned-production`
        
    * - proxy.storage.s3.scanned-container-name
      - :code:`scanned-production`
        
    * - internal.snapassert.signing.revisions.key
      - :code:`None`
        
    * - internal.snapassert.signing.revisions.key-id
      - :code:`None`
        
    * - internal.snapassert.signing.revisions.account-id
      - :code:`None`
        
    * - internal.publishergw.snapmodels.read-timeout
      - :code:`15`
        
    * - internal.airgap.gateway-hash
      - None
        
    * - internal.airgap.store.admin.id
      - None
        
    * - internal.airgap.store.admin.macaroon-sha3-384
      - None
        
    * - internal.airgap.store.provenance-allowlist
      - None
        
    * - internal.storeadmingw.admin-auth-token
      - None
        
    * - internal.snapstorage.local-origin-secret
      - None
        
    * - internal.snapstorage.hmac-shared-key
      - None
        