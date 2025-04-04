---
title: Overrides API
table_of_contents: true
---

# Overrides API

The Overrides API supports two operations: list overrides, and set overrides.

All operations require an "Authorisation" header, as described in [API authentication](api-authentication.md).

## List overrides

To list overrides for a snap name, perform a `GET` request to `/v2/metadata/overrides/{snap_name}`:

Example: to list overrides for `snap_a`:

Request:

```http
GET /v2/metadata/overrides/snap_a HTTP/1.1
Host: <store domain>
Accept: application/json
X-Ubuntu-Series: 16

```
Note the `X-Ubuntu-Series` header.

Response:

```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
    "overrides": [
        {
            "snap_id": ...,
            "snap_name": "snap_a",
            "revision": 20,
            "upstream_revision": 23,
            "channel": "stable",
            "architecture": "x86",
            "series": "16"
        }
    ]
}
```

The JSON Schema for the response document is:

```
{
    "type": "object",
    "properties": {
        "overrides": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "snap_id": {"type": "string"},
                    "snap_name": {"type": "string"},
                    "revision": {
                        "type": "integer",
                        "minimum": 1,
                    },
                    "upstream_revision": {
                        "type": ["integer", "null"],
                        "minimum": 1,
                    },
                    "channel": {"type": "string"},
                    "architecture": {"type": "string"},
                    "series": {"type": "string"},
                },
                "required": [
                    "snap_id", "snap_name", "revision", "upstream_revision",
                    "channel", "architecture", "series",
                ],
                "additionalProperties": False,
            },
        },
    },
    "required": ["overrides"],
    "additionalProperties": False,
}
```

## Set overrides

To set overrides, perform a `POST` request to `/v2/metadata/overrides`.

Example: override `snap_a` to revision 20 on the stable channel, and remove any
overrides for `snap_b` on the candidate channel.

Request:

```http
POST /v2/metadata/overrides HTTP/1.1
Host: <store domain>
Accept: application/json
Content-Type: application/json

[
    {
        "snap_name": "snap_a",
        "revision": 20,
        "channel": "stable",
        "series": "16"
    },
    {
        "snap_name": "snap_b",
        "revision": null,
        "channel": "candidate",
        "series": "16"
    }
]
```

Response:

```
HTTP/1.1 200 OK
Content-Type: application/json
...

{
    "overrides": [
        {
            "snap_id": ...,
            "snap_name": "snap_a",
            "revision": 20,
            "upstream_revision": 23,
            "channel": "stable",
            "architecture": "x86",
            "series": "16"
        }, {
            "snap_id": ...,
            "snap_name": "snap_b",
            "revision": null,
            "upstream_revision": 13,
            "channel": "candidate",
            "architecture": "x86",
            "series": "16"
        }
    ]
}

```

The request body format should match the following JSON schema.

```
{
    "type": "array",
    "items": {
        "type": "object",
        "properties": {
            "snap_name": {"type": "string"},
            "revision": {
                "type": ["integer", "null"],
                "minimum": 1,
            },
            "channel": {"type": "string"},
            "series": {"type": "string"},
        },
        "required": ["snap_name", "revision", "channel", "series"],
        "additionalProperties": False,
    },
    "minItems": 1,
}
```

To delete an override, simply set its revision field to `null`. The "series" field
must be set to "16" currently.

The response includes the results of the operation. The response format is the
same as for listing overrides, except that "revision" can be `null` if an
override was deleted.
