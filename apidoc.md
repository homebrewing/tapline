Overview
========
Tapline provides an API server for homebrewers that is split into two parts: public anonymous calls to various converters & calculators, and authenticated calls to access the majority of the APIs. Tapline can be accessed at the following URL:

 * https://api.malt.io/

Calculators & Converters
========================
Public, anonymous API methods to convert between various representations and to calculate homebrewing information.

Converting Durations
--------------------
Converts up to 25 durations from a number of minutes or a string representation into a number of minutes (`outputFormat` is `minutes`) or a human-readable string format (`outputFormat` is `display`). An optional `approximate` parameter will approximate the duration if `outputFormat` is `display`, e.g. a value of `1` would display hours but truncate minutes if `65` minutes are input. The `approximate` parameter rounds the last displayed value.

### Request
```http
POST /v1/convert/duration.json HTTP/1.1
Content-Type: application/json

{
    "values": [
        5823,
        "1 day 23 hours 2min",
        "60hrs"
    ],
    "outputFormat": "display"
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: ahsdf4h6
X-Response-Time: 4ms

{
    "format": "display",
    "values": [
        "4 days 1 hour 3 minutes", 
        "1 day 23 hours 2 minutes", 
        "2 days 12 hours"
    ]
}
```

### Errors

| Code | Description               |
| ---- | ------------------------- |
| 400  | Invalid request arguments |
| 500  | Internal server error     |

Converting Colors
-----------------
Converts up to 25 colors from SRM, EBC, or Lovibond into SRM, EBC, Lovibond, RGB, CSS color string, or human-readable color name. Valid input formats: `srm`, `ebc`, `lovibond`. Valid output formats: `srm`, `ebc`, `lovibond`, `rgb`, `css`, `name`.

### Request
```http
POST /v1/convert/color.json HTTP/1.1
Content-Type: application/json

{
    "format": "srm",
    "values": [
        4,
        9,
        15,
        20,
        28
    ]
    "outputFormat": "ebc"
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: fa28de76
X-Response-Time: 2ms

{
    "format": "ebc",
    "values": [
        7.88,
        17.73,
        29.55,
        39.4,
        55.16
    ]
}
```

### Errors

| Code | Description               |
| ---- | ------------------------- |
| 400  | Invalid request arguments |
| 500  | Internal server error     |

Converting Recipes
------------------
Converts up to 10 recipes from/to a Brauhaus JSON representation and BeerXML. Valid input and output formats are `json` and `beerxml`.

### Request
```http
POST /v1/convert/recipe.json HTTP/1.1
Content-Type: application/json

{
    "format": "beerxml",
    "recipes": [
        "<recipes><recipe><version>1</version><name>Test</name><fermentables><fermentable><name>Pale extract</name><amount>3.5</amount><yield>75</yield></fermentable></fermentables></recipe></recipes>"
    ],
    "outputFormat": "json"
}
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 8145460e
X-Response-Time: 11ms

{
    "format": "json", 
    "recipes": [
        {
            "agingDays": 14, 
            "agingTemp": 20, 
            "author": "Anonymous Brewer", 
            "batchSize": 20, 
            "boilSize": 10, 
            "bottlingPressure": 0, 
            "bottlingTemp": 0, 
            "description": "Recipe description", 
            "fermentables": [
                {
                    "color": 2, 
                    "late": false, 
                    "name": "Pale extract", 
                    "weight": 3.5, 
                    "yield": 75
                }
            ], 
            "ibuMethod": "tinseth", 
            "mash": null, 
            "mashEfficiency": 75, 
            "name": "Test", 
            "primaryDays": 14, 
            "primaryTemp": 20, 
            "secondaryDays": 0, 
            "secondaryTemp": 0, 
            "servingSize": 0.355, 
            "spices": [], 
            "steepEfficiency": 50, 
            "steepTime": 20, 
            "style": null, 
            "tertiaryDays": 0, 
            "tertiaryTemp": 0, 
            "yeast": []
        }
    ]
}

```

### Errors

| Code | Description               |
| ---- | ------------------------- |
| 400  | Invalid request arguments |
| 500  | Internal server error     |

Authentication & Authorization
==============================
There are three types of requests in Tapline:

 1. Public (no authentication)
 2. Requests for authorization (HTTP basic auth)
 3. Requests on behalf of a user (OAuth bearer token)

Public requests need no authentication and do not fall within this and the following sections. Authentication and authorization in Tapline allow third party __clients__ to make API requests _on behalf_ of __users__ using an opaque _token_. In order to get such a token, a third party client has two options:

 1. Web flow (TODO)
 2. Authorizations API

Web Flow
--------
Coming soon. For now you can manually create authorizations using the section below.

Scopes
------
OAuth2 scopes are a way to control access to resources. They allow a user to give only specific permissions to a third party client, such as modifying recipes but not giving access to the user's email address. The following scopes are available in Tapline:

 * Coming soon!

Authorizations API
------------------
The authorizations API is a bit different from other calls in Tapline, in that it requires HTTP basic auth along with third party client information for every request instead of using OAuth bearer tokens. This means that the authorizations API requires that you temporarily collect a user's name and password until you can get an OAuth2 bearer token.

The authorizations API is heavily inspired by the [Github API](http://developer.github.com/v3/oauth/).

### Create an Authorization Token
Create a new authorization for a third party client and a specific user. The response will give you an OAuth bearer token to use for authorized API requests on behalf of that user with the given scopes, if any. The request __must__ use HTTP basic auth (the `Authorization` header below) using the user's `name` and `password`, as well as including the `clientId` and `clientSecret` of the registered third party client.

#### Request
```http
POST /v1/authorizations.json HTTP/1.1
Content-Type: application/json
Authorization: Basic ZGFuaWVsOmFiYzEyMw==

{
    "clientId": "abc123",
    "clientSecret": "some-secret",
    "scopes": [
        "user",
        "recipe"
    ]
}
```

#### Response
```http
HTTP/1.1 201 Created
Content-Type: application/json
X-Request-ID: 64a359b2
X-Response-Time: 100ms

{
    "clientId": "abc123",
    "created": "2013-07-11T17:28:52.787Z",
    "id": "51deeb54763ce70000000001",
    "scopes": [
        "profile",
        "recipe"
    ],
    "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
    "userId": "51de54131084ffeef8000001"
}
```

#### Errors

| Code | Description                            |
| ---- | -------------------------------------- |
| 400  | Invalid request arguments              |
| 401  | Invalid user/password or client/secret |
| 500  | Internal server error                  |

### Listing Authorization Tokens
List a third-party client's authorization tokens for a specific user. The responses will give you a OAuth bearer tokens to use for authorized API requests on behalf of that user with the given scopes, if any. The request __must__ use HTTP basic auth (the `Authorization` header below) using the user's `name` and `password`, as well as including the `clientId` and `clientSecret` of the registered third party client.

#### Request
```http
GET /v1/authorizations.json?clientId=abc123&clientSecret=some-secret HTTP/1.1
Content-Type: application/json
Authorization: Basic ZGFuaWVsOmFiYzEyMw==
```

#### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 64a359b2
X-Response-Time: 100ms

[
    {
        "clientId": "abc123",
        "created": "2013-07-11T17:28:52.787Z",
        "id": "51deeb54763ce70000000001",
        "scopes": [
            "profile",
            "recipe"
        ],
        "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
        "userId": "51de54131084ffeef8000001"
    }
]
```

#### Errors

| Code | Description                            |
| ---- | -------------------------------------- |
| 400  | Invalid request arguments              |
| 401  | Invalid user/password or client/secret |
| 500  | Internal server error                  |

### Update an Authorization Token
Update an existing authorization by its unique id. The request __must__ use HTTP basic auth (the `Authorization` header below) using the user's `name` and `password`, as well as including the `clientId` and `clientSecret` of the registered third party client.

Scopes can be set to a new list via `scopes`, appended to via `addScopes` or removed from via `removeScopes`. One of these three is required. Passing more than one will result in an error.

#### Request
```http
PUT /v1/authorizations/51deeb54763ce70000000001.json HTTP/1.1
Content-Type: application/json
Authorization: Basic ZGFuaWVsOmFiYzEyMw==

{
    "clientId": "abc123",
    "clientSecret": "some-secret",
    "addScopes": [
        "profile:delete"
    ]
}
```

#### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 64a359b2
X-Response-Time: 100ms

{
    "clientId": "abc123",
    "created": "2013-07-11T17:28:52.787Z",
    "id": "51deeb54763ce70000000001",
    "scopes": [
        "profile",
        "profile:delete",
        "recipe"
    ],
    "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
    "userId": "51de54131084ffeef8000001"
}
```

#### Errors

| Code | Description                            |
| ---- | -------------------------------------- |
| 400  | Invalid request arguments              |
| 401  | Invalid user/password or client/secret |
| 500  | Internal server error                  |

### Delete an Authorization Token
Delete an existing authorization by its unique id. The request __must__ use HTTP basic auth (the `Authorization` header below) using the user's `name` and `password`, as well as including the `clientId` and `clientSecret` of the registered third party client.

#### Request
```http
DELETE /v1/authorizations/51deeb54763ce70000000001.json HTTP/1.1
Content-Type: application/json
Authorization: Basic ZGFuaWVsOmFiYzEyMw==

{
    "clientId": "abc123",
    "clientSecret": "some-secret"
}
```

#### Response
```http
HTTP/1.1 204 No Content
Content-Type: application/json
X-Request-ID: 64a359b2
X-Response-Time: 100ms


```

#### Errors

| Code | Description                            |
| ---- | -------------------------------------- |
| 400  | Invalid request arguments              |
| 401  | Invalid user/password or client/secret |
| 500  | Internal server error                  |

User Accounts
=============
User accounts are the owners of data within Tapline. Users own recipes, brew days, follow other users, etc.

Registering a New User
----------------------
This method __does not require authentication or authorization__. A new user can be registered with the service using an only an `email`, `name` and `password`.

The user `name` should be made up of lowercase letters, numbers, `-` and `_` so that it is safe to be used in URLs.

### Request
```http
POST /v1/users.json HTTP/1.1
Content-Type: application/json

{
    "email": "user@domain.com",
    "name": "my_cool_username",
    "password": "myP@ssW0rD"
}
```

### Response
```http
HTTP/1.1 201 Created
Content-Type: application/json
X-Request-ID: 60b03d63
X-Response-Time: 240ms

{
    "confirmed": false,
    "created": "2013-07-09T04:19:13.213Z",
    "id": "51db8f41dd6939ffb9000001",
    "name": "my_cool_username",
    "recipeCount": 0
}
```

### Errors

| Code | Description                                   |
| ---- | --------------------------------------------- |
| 400  | Invalid request arguments, duplicate username |
| 500  | Internal server error                         |

Listing Users
-------------
Get a list of users. Two parameters are used for pagination: `offset` which defines the number of results skip and `limit` which defines how many results to return up to 60. The defaults are `0` and `20`. Sorting is accomplished via the `sort` parameter which can be one of `name`, `-name`, `created`, `-created`, `recipeCount`, `-recipeCount`. The default sort is `name`.

### Request
```http
GET /v1/users.json?offset=10&limit=10&sort=-recipeCount HTTP/1.1
Content-Type: application/json
Authorization: Bearer b608d4b097c838067aba07eb9206faab1bf4b446
```

### Response
```http
HTTP/1.1 200 OK
Content-Type: application/json
X-Request-ID: 60b03d63
X-Response-Time: 40ms

[
    {
        "confirmed": false,
        "created": "2013-07-09T04:19:13.213Z",
        "id": "51db8f41dd6939ffb9000001",
        "name": "my_cool_username",
        "recipeCount": 0
    }
]
```

### Errors

| Code | Description                 |
| ---- | --------------------------- |
| 400  | Invalid request arguments   |
| 401  | Invalid OAuth2 bearer token |
| 500  | Internal server error       |

Recipes
=======

TODO!
