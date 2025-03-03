---
title: API authentication
table_of_contents: true
---

# API authentication

Authentication with the API requires a valid Ubuntu SSO user. This user
must be configured as an admin using the `snap-proxy` tool:

```bash
snap-proxy add-admin user@example.com
```

The Snap Store and Enterprise Store use macaroons for authentication,
which are a kind of bearer token that can be constrained and that can
be authorised by third-party services.  We strongly recommend using
[pymacaroons](https://github.com/ecordell/pymacaroons) or
[libmacaroons](https://github.com/rescrv/libmacaroons) to work with
these tokens.

If you want to understand more about how macaroons work, refer to the [original
paper](https://research.google.com/pubs/pub41892.html).


To login, you must first get a root macaroon from the Enterprise Store,
then discharge (verify) that macaroon with [Ubuntu SSO](https://login.ubuntu.com/).

## Root Macaroon

To get a root macaroon:

Request:

```http
POST /v2/auth/issue-store-admin HTTP/1.1
Host: <store domain>
Accept: application/json
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
    "macaroon": "..."
}
```

The response is simple and matches this JSON Schema:

```
{
    'type': 'object',
    'properties': {
        'macaroon': {'type': 'string'},
    },
    'required': ['macaroon'],
    'additionalProperties': False,
}
```

This is your main authentication token, and should be stored persistently.

## Discharge Ubuntu SSO caveat

The root macaroon contains a caveat that the user must have a valid
Ubuntu SSO account. To prove that is the case, we need to discharge that
caveat with Ubuntu SSO.

You need to deserialise this root macaroon, and extract the caveat ID
with the location `login.ubuntu.com`. For example, using pymacaroons:

```python
macaroon = pymacaroons.Macaroon.deserialize(root_macaroon)
for caveat in macaroon.caveats:
    if caveat.location == 'login.ubuntu.com':
        return caveat.caveat_id
```

Then we need to discharge the caveat with Ubuntu SSO.

Request:

```
POST /api/v2/tokens/discharge HTTP/1.1
Host: login.ubuntu.com
Accept: application/json
Content-Type: application/json

{
    "email": ...,
    "password": ...,
    "otp": ...,  # if user account has 2FA enabled
    "caveat_id": ...
}
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
    "discharge_macaroon": "<discharge macaroon>",
}
```

```{note}
For more detailed responses from Ubuntu SSO, particularly handling
invalid credentials and 2FA, see the  general 
[Ubuntu SSO documentation for OAuth tokens](
http://canonical-identity-provider.readthedocs.io/en/latest/resources/token.html),
which is also used by the macaroon discharge endpoint.
```

You will need to persist the raw root macaroon and the raw discharge
macaroon.  Together, these are your authentication.

## Request authentication

To authenticate a request, you must bind the discharge macaroon to the
root macaroon, and send that as your value in an 'Authorisation' HTTP
header.

For example, with pymacaroons:

```python
root = pymacaroon.Macaroon.deserialize(root_raw)
discharge = pymacaroons.Macaroon.deserialize(discharge_raw)
bound = root.prepare_for_request(discharge)
header = 'Macaroon root="{}", discharge="{}"'.format(root_raw, bound.serialize())
```

```{note}
If your discharge macaroon has expired, it will be indicated by
indicated by a 401 status code, and a header:
`HTTP/1.1 401 Unauthorized WWW-Authenticate: Macaroon needs_refresh=1`
```

In this case you will need to refresh your discharge macaroon, described below,
and retry the request.

## Refreshing the discharge macaroon

Your discharge macaroon has an expiry, and needs refreshing with Ubuntu
SSO periodically.

To do so, simply:

Request:
```http
POST /api/v2/tokens/refresh HTTP/1.1
Host: login.ubuntu.com
Accept: application/json
Content-Type: application/json

{
    "discharge_macaroon": "<discharge>"
}
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
    "discharge_macaroon": "<new discharge>",
}
```

Update and store persistently this new discharge macaroon for later use.
