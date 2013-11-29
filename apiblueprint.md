FORMAT: 1A
HOST: https://api.malt.io

Tapline Homebrewing API
=======================
Tapline is an API for [Malt.io](http://beta.malt.io/), a homebrewing community website. It provides access to users, recipes, and conversion/calculation functions that any client can use if they can speak HTTPS and JSON.

Tapline is split into two logical components. You can use just one of these, or both if your application requires it. The simplest is the public API because it does not require getting authorization from an existing user nor sending any special headers. Be aware that the public API provides **read-only** access to stored state like recipes. To create, edit, or delete recipes you must use the authenticated API instead.

 1. Public API

    * Utility functions

    * Read-only access to users, recipes, etc

    * Creating new users

    * Getting authorizations

 1. Authenticated API

    * Full access to users, recipes, etc

## Examples

 * [Display a list of users](http://jsfiddle.net/danielgtaylor/vn3Rt/)

## Formats
JSON is the primary format used within Tapline, but for the HTTP `GET` request method query arguments are typically used. For example, to get a list of recipes:

```http
GET /v1/public/recipes?limit=5&sort=name HTTP/1.1
```

The above uses HTTP query parameters, while `POST`, `PUT`, and `DELETE` methods use JSON. For example, modifying a recipe would use a JSON content body:

```http
PUT /v1/recipes/3jl452lk42h3 HTTP/1.1
Content-Type: application/json
Authorization: bearer k4j534h53j4lh53l4j5

{
    private: false,
    recipe: {
        "name": "My Recipe",
        "description": "...",
        ...
    }
}
```

Responses will always return JSON when successful, and a plain text error message when an error has occured. For example:

```http
HTTP/1.1 200 OK
Content-Type: application/json; charset=utf-8
X-Request-ID: k23l4j2
X-Response-Time: 16ms

{
    "id": "23k4j2k3j42h34",
    "name": "User name",
    ...
}
```

An error, on the other hand, would be returned like this:

```http
HTTP/1.1 400 BAD REQUEST
Content-Type: text/html
X-Request-ID: hf324d6j
X-Response-Time: 2ms

Error: JSON object property 'sort' is not in enum
```

## User Profile Images
Users have an assigned profile image URL, available in the `image` property of the user object. The URL should have a text replacement run on it before being used. A typical image URL may look like:

```no-highlight
http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro
```

Before use, the `SIZE` string would be replaced with an appropriate size in pixels, for example:

```no-highlight
http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=64&d=retro
```

# Group Anonymous Public API
Public calls that do not require authentication. These calls cannot change stored state - for example you can only **read** recipes, not **write** them. See the authenticated API calls for information on how to write data on behalf of a user.

## Convert Duration [/v1/convert/duration]

+ Parameters

    + values (required, array, `[1, 2]`) ... List of durations to convert
    + outputFormat = `minutes` (optional, string, `display`) ... Output format

        + Values
            + `minutes`
            + `display`

    + approximate (optional, integer, `2`) ... Approximate the display duration to this many significant units. For example, `'2 days 1 hour 15 minutes'` approximated to `2` would be `'2 days 1 hour'`.

### Convert [POST]
Utilities to convert one or more representations of durations. Converts between a number of minutes and a user-friendly string representation of a duration.

+ Request

    + Headers

            Content-Type: application/json

    + Body

        {
            "values": [
                5823,
                "1 day 23 hours 2min",
                "60hrs"
            ],
            "outputFormat": "display"
        }

+ Response 200

    + Headers

            Content-Type: application/json

    + Body

        {
            "format": "display",
            "values": [
                "4 days 1 hour 3 minutes", 
                "1 day 23 hours 2 minutes", 
                "2 days 12 hours"
            ]
        }

+ Response 400

    Invalid output format 'foo'!

## Convert Color [/v1/convert/color]

+ Parameters

    + format (required, string, `ebc`) ... Input format

        + Values
            + `ebc`
            + `srm`
            + `lovibond`

    + values (required, array, `[1, 2]`) ... List of colors to convert
    + outputFormat = `ebc` (optional, string, `srm`) ... Output format

        + Values
            + `ebc`
            + `srm`
            + `lovibond`
            + `name`
            + `rgb`
            + `css`

### Convert [POST]
Utilities to convert one or more representations of colors.

+ Request

    + Headers

            Content-Type: application/json

    + Body

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

+ Response 200

    + Headers

            Content-Type: application/json

    + Body

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

+ Response 400

    Invalid output format 'foo'!

## Convert Recipe [/v1/convert/recipe]

+ Parameters

    + format (required, string, `beerxml`) ... Input format

        + Values
            + `json`
            + `beerxml`

    + recipes (required, array, `['<beerxml>...</beerxml>']`) ... List of recipes to convert
    + outputFormat = `json` (optional, string, `beerxml`) ... Output format

        + Values
            + `json`
            + `beerxml`

### Convert [POST]
Utilities to convert one or more representations of a serialized recipe. Currently supported are BeerXML 1.0 and the Brauhaus JSON format. Note that these conversions are not 1:1, so you may lose data by converting between formats. For example, Brauhaus JSON stores the IBU calculation method while BeerXML does not.

+ Request

    + Headers

            Content-Type: application/json

    + Body

        {
            "format": "beerxml",
            "recipes": [
                "<recipes><recipe><version>1</version><name>Test</name><fermentables><fermentable><name>Pale extract</name><amount>3.5</amount><yield>75</yield></fermentable></fermentables></recipe></recipes>"
            ],
            "outputFormat": "json"
        }

+ Response 200

    + Headers

            Content-Type: application/json

    + Body

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

+ Response 400

    Invalid output format 'foo'!

## Calculate Recipe [/v1/calculate/recipe]

+ Parameters

    + format (required, string, `beerxml`) ... Input format

        + Values
            + `json`
            + `beerxml`

    + recipes (required, array, `['<beerxml>...</beerxml>']`) ... List of recipes to convert
    + siUnits = `true` (optional, boolean, `false`) ... True to use kg, liters and &deg;C instead of lb, oz, gallons, and &deg;F

### Calculate [POST]
Utilities to calculate the OG, FG, IBU, ABV, and other values from one or more serialized recipes. This method also generates a brew day timeline for the recipe.

+ Request

    + Headers

            Content-Type: application/json

    + Body

        {
            "format": "beerxml",
            "recipes": [
                "<recipes><recipe><version>1</version><name>Test</name><fermentables><fermentable><name>Pale extract</name><amount>3.5</amount><yield>75</yield></fermentable></fermentables></recipe></recipes>"
            ],
            "siUnits": true
        }

+ Response 200

    + Headers

            Content-Type: application/json

    + Body

        [
            {
                "abv": 4.982895960844915, 
                "abw": 3.8872943605883177, 
                "buToGu": 0, 
                "bv": 0, 
                "calories": 165.65117039861516, 
                "color": 3.1126033196646703, 
                "fg": 1.0126549326899237, 
                "fgPlato": 3.2323394802073437, 
                "grainWeight": 0, 
                "ibu": 0, 
                "og": 1.0506197307596945, 
                "ogPlato": 12.534722891468903, 
                "price": 15.400000000000002, 
                "realExtract": 4.914210400963434, 
                "timeline": [
                    [
                        0, 
                        "Bring 10.0l to a rolling boil (about 21 minutes)."
                    ], 
                    [
                        21, 
                        "Flame out. Begin chilling to 20°C and aerate the cooled wort (about 20 minutes)."
                    ], 
                    [
                        41, 
                        "Pitch yeast and seal the fermenter. You should see bubbles in the airlock within 24 hours."
                    ], 
                    [
                        20201, 
                        "Prime and bottle about 56 bottles. Age at 20C for 14 days."
                    ], 
                    [
                        40361, 
                        "Relax, don't worry and have a homebrew!"
                    ]
                ]
            }
        ]

+ Response 400

    Invalid input format 'foo'!

## Recipe Collection [/v1/public/recipes]
A collection of public homebrew recipes.

+ Parameters

    + ids (optional, string, `100,102,105`) ... List of recipe IDs
    + userIds (optional, string, `200,201,204`) ... List of recipe owner user IDs
    + slugs (optional, string, `test-recipe,hefeweizen`) ... List of recipe slugs to find in conjunction with `userIds`
    + offset = `0` (optional, integer, `0`) ... Number of recipes to skip
    + limit = `20` (optional, integer, `30`) ... Number of recipes returned
    + sort = `-created` (optional, string, `name`) ... Sort method
    
        + Values
            + `created`
            + `-created`
            + `name`
            + `-name`

    + detail = `false` (optional, boolean, `true`) ... Whether to show detailed info

+ Model
A list of recipes

    + Headers
    
            Content-Type: application/json; charset=utf-8

    + Body

            [
                {
                    "created": "2013-11-02T17:25:51.275Z", 
                    "data": {
                        "agingDays": 14, 
                        "agingTemp": 20, 
                        "agingTempF": 68, 
                        "author": "Anonymous Brewer", 
                        "batchSize": 20, 
                        "batchSizeGallons": 5.283440000000001, 
                        "boilSize": 10, 
                        "boilSizeGallons": 2.6417200000000003, 
                        "bottlingPressure": 2.5, 
                        "bottlingTemp": 23, 
                        "bottlingTempF": 73.4, 
                        "description": "Just a basic beer example for testing. foo this is a long description", 
                        "fermentables": [
                            {
                                "color": 6.096, 
                                "late": false, 
                                "name": "Extra pale extract", 
                                "weight": 4.5, 
                                "yield": 75
                            }
                        ], 
                        "ibuMethod": "tinseth", 
                        "mash": null, 
                        "mashEfficiency": 75, 
                        "name": "Another Beer 2", 
                        "primaryDays": 14, 
                        "primaryTemp": 20, 
                        "primaryTempF": 68, 
                        "secondaryDays": 0, 
                        "secondaryTemp": 0, 
                        "secondaryTempF": 32, 
                        "servingSize": 0.355, 
                        "servingSizeOz": 0.09378106, 
                        "spices": [
                            {
                                "aa": 4.5, 
                                "form": "pellet", 
                                "name": "Cascade hops", 
                                "time": 60, 
                                "use": "boil", 
                                "weight": 0.028349556839727483
                            }
                        ], 
                        "steepEfficiency": 50, 
                        "steepTime": 20, 
                        "style": null, 
                        "tertiaryDays": 0, 
                        "tertiaryTemp": 0, 
                        "tertiaryTempF": 32, 
                        "yeast": [
                            {
                                "attenuation": 74, 
                                "form": "liquid", 
                                "name": "Wyeast 3052", 
                                "type": "ale"
                            }
                        ]
                    }, 
                    "id": "5275359f031555931a000005", 
                    "private": false, 
                    "slug": "another-beer-2", 
                    "user": {
                        "id": "51de54131084ffeef8000001", 
                        "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                        "name": "daniel"
                    }
                }, 
                {
                    "created": "2013-10-24T20:39:23.320Z", 
                    "data": {
                        "agingDays": 14, 
                        "agingTemp": 20, 
                        "agingTempF": 68, 
                        "author": "Anonymous Brewer", 
                        "batchSize": 20, 
                        "batchSizeGallons": 5.283440000000001, 
                        "boilSize": 10, 
                        "boilSizeGallons": 2.6417200000000003, 
                        "bottlingPressure": 2.5, 
                        "bottlingTemp": 23, 
                        "bottlingTempF": 73.4, 
                        "description": "Just a basic beer example for testing. foo this is a long description", 
                        "fermentables": [
                            {
                                "color": 1.27, 
                                "late": false, 
                                "name": "Extra pale extract", 
                                "weight": 4.5, 
                                "yield": 75
                            }
                        ], 
                        "ibuMethod": "tinseth", 
                        "mash": null, 
                        "mashEfficiency": 75, 
                        "name": "Hefeweizen", 
                        "primaryDays": 14, 
                        "primaryTemp": 20, 
                        "primaryTempF": 68, 
                        "secondaryDays": 0, 
                        "secondaryTemp": 0, 
                        "secondaryTempF": 32, 
                        "servingSize": 0.355, 
                        "servingSizeOz": 0.09378106, 
                        "spices": [
                            {
                                "aa": 4.5, 
                                "form": "pellet", 
                                "name": "Cascade hops", 
                                "time": 60, 
                                "use": "boil", 
                                "weight": 0.028349556839727483
                            }
                        ], 
                        "steepEfficiency": 50, 
                        "steepTime": 20, 
                        "style": null, 
                        "tertiaryDays": 0, 
                        "tertiaryTemp": 0, 
                        "tertiaryTempF": 32, 
                        "yeast": [
                            {
                                "attenuation": 74, 
                                "form": "liquid", 
                                "name": "Wyeast 3052", 
                                "type": "ale"
                            }
                        ]
                    }, 
                    "id": "5269857b7011ba8186000001", 
                    "private": false, 
                    "slug": "hefeweizen", 
                    "user": {
                        "id": "51de54131084ffeef8000001", 
                        "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                        "name": "daniel"
                    }
                }
            ]

### Get recipes [GET]
Gets a list of public recipes given the input parameters for filtering and sorting. An example call would look like this:

```no-highlight
https://api.malt.io/v1/public/recipes?detail=true
```

+ Response 200

    [Recipe Collection][]

+ Response 400

    Invalid sort option

## Actions Collection [/v1/public/actions]
A collection of public actions taken by users, such as creating a new recipe or following another brewer.

+ Model
A list of user actions.

    + Headers
    
            Content-Type: application/json; charset=utf-8

    + Body

            [
                {
                    "created": "2013-11-12T05:52:58.487Z", 
                    "data": {
                        "abv": 6.294638860098035, 
                        "color": 7.9427671464530025, 
                        "description": "Just a basic beer example for testing. foo this is a long description", 
                        "fg": 1.016921452853955, 
                        "ibu": 8.232188432976319, 
                        "name": "Another Beer 2", 
                        "og": 1.0650825109767499, 
                        "slug": "another-beer-2"
                    }, 
                    "id": "5281c23a5889ca3e8b000001", 
                    "private": false, 
                    "targetId": "5275359f031555931a000005", 
                    "type": "recipe-updated", 
                    "user": {
                        "id": "51de54131084ffeef8000001", 
                        "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                        "name": "daniel"
                    }
                }, 
                {
                    "created": "2013-11-12T00:23:43.863Z", 
                    "data": {
                        "abv": 6.294638860098035, 
                        "color": 7.9427671464530025, 
                        "description": "Just a basic beer example for testing. foo this is a long description", 
                        "fg": 1.016921452853955, 
                        "ibu": 8.232188432976319, 
                        "name": "Another Beer 2", 
                        "og": 1.0650825109767499, 
                        "slug": "another-beer-2"
                    }, 
                    "id": "5281750f0f7d42a578000004", 
                    "private": false, 
                    "targetId": "5275359f031555931a000005", 
                    "type": "recipe-updated", 
                    "user": {
                        "id": "51de54131084ffeef8000001", 
                        "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                        "name": "daniel"
                    }
                },
            ]

### Get actions [GET]
Gets a list of public user actions with the given options for filtering and sorting. An example call would look like this:

```no-highlight
https://api.malt.io/v1/public/actions?userIds=id1,id2,id3
```

+ Parameters

    + userIds (optional, array, `['id1', 'id2']`) ... List of user IDs
    + ids (optional, array, `['id1', 'id2']`) ... List of action IDs
    + offset = `0` (optional, integer, `0`) ... Number of recipes to skip
    + limit = `20` (optional, integer, `30`) ... Number of recipes returned
    + sort = `name` (optional, string, `-created`) ... Sort method
    
        + Values
            + `created`
            + `-created`

+ Response 200

    [Actions Collection][]

+ Response 400

    Invalid sort option

## User Collection [/v1/public/users]
A collection of public users.

+ Parameters

    + ids (optional, string, `101,102`) ... List of user IDs
    + names (optional, string, `daniel,kari`) ... List of usernames
    + offset = `0` (optional, integer, `0`) ... Number of recipes to skip
    + limit = `20` (optional, integer, `30`) ... Number of recipes returned
    + sort = `name` (optional, string, `-created`) ... Sort method
    
        + Values
            + `created`
            + `-created`
            + `name`
            + `-name`
            + `recipeCount`
            + `-recipeCount`
            + `location`
    
    + fromLong (optional, number, `-122.3`) ... Longitude to find nearby users when `sort` is `location`
    + fromLat (optional, number, `47.6`) ... Latitude to find nearby users when `sort` is `location`

+ Model

    + Headers

            Content-Type: application/json; charset=utf-8

    + Body

            [
                {
                    "confirmed": true, 
                    "created": "2013-07-11T06:43:31.988Z", 
                    "following": [], 
                    "id": "51de54131084ffeef8000001", 
                    "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                    "location": [
                        -122.331, 
                        47.61
                    ], 
                    "name": "daniel", 
                    "recipeCount": 0
                }, 
                {
                    "confirmed": false, 
                    "created": "2013-08-01T00:54:44.656Z", 
                    "following": [], 
                    "id": "51f9b1d45946118c34000001", 
                    "image": "https://plus.google.com/s2/photos/profile/117442582930902051362?sz=SIZE", 
                    "location": [
                        -122.331, 
                        47.61
                    ], 
                    "name": "daniel-taylor", 
                    "recipeCount": 0
                }
            ]

### Get users [GET]
Gets a list of public users given the input parameters for filtering and sorting. An example call would look like this:

```no-highlight
https://api.malt.io/v1/public/users?limit=5
```

+ Response 200

    [User Collection][]

+ Response 400
    
    Invalid sort option

## Register new user [/v1/users]
Registers a new user account with a username and password. This user will not be able to use social authentication to log in, and instead must use a username and password. The user account will remain unverified until a link from the confirmation email is clicked.

### POST

+ Parameters

    + email (required, string, `foo@bar.com`) ... The user's email address (not visible to others)
    + name (required, string, `username`) ... A unique user name
    + image (required, string, `http://...`) ... URL to an image of the user
    + location (required, array, `[-122.331, 47.61]`) ... The location of the user, as `[latitude, longitude]` in degrees. Seattle (47.61&deg;N, 122.331&deg;W) would be `[-122.331, 47.61]`.

+ Request

    + Headers

            Content-Type: application/json

    + Body

        {
            "email": "foo@bar.com",
            "name": "username",
            "image": "http://foo.com/bar.jpg?size=SIZE",
            "location": [-122.331, 47.61]
        }

+ Response 201 (application/json)

    + Body

        {
            "confirmed": false, 
            "created": "2013-11-01T00:54:44.656Z", 
            "following": [], 
            "id": "51f9b1d45946118c34000001", 
            "image": "http://foo.com/bar.jpg?size=SIZE", 
            "location": [
                -122.331, 
                47.61
            ], 
            "name": "username", 
            "recipeCount": 0
        }

+ Response 400

    Invalid username!

# Group Authentication
The API is split into two parts: the public API and the authenticated API. The public API described above requires no authentication. The authenticated API (everything after this section), on the other hand, **requires** an OAuth bearer token in an HTTP authorization header. For example, the header might look like this:

```http
Authorization: bearer 5262d64b892e8d4341000001
```

In order to get an authorization token, you must first register an application. Then, using your application token you request access on behalf of a user and are given an OAuth bearer token to use for subsequent requests. The OAuth bearer token is proof that a specific user has given your specific application access to use the API on his or her behalf.

## Registering an application
**TODO**: Describe how to register a new application and manage applications.

## Authorization scopes
The following scopes are available to your application. You should only request scopes that your application needs. Keep in mind that requesting destructive scopes may drive users away from your application. As you can see in the table, reading of public data requires no scopes - it is only writing and deleting of data or viewing private data that requires you to specify scopes.

| Item                        | Read         | Write              | Delete          |
| --------------------------- | ------------ | ------------------ | --------------- |
| Public user account info    | -            | `user`             | `user:delete`   |
| Public user actions         | -            | `user` or `recipe` | n/a             |
| Public recipes              | -            | `recipe`           | `recipe:delete` |
| Public brews                | -            | `recipe`           | `recipe:delete` |
| Private account email       | `user:email` | n/a                | n/a             |
| Private actions and recipes | `private`    | `private`          | `private`       |

## Getting an OAuth token
There are several ways of getting an OAuth bearer token. Typical web or mobile applications will use a special URI that redirects a user to log in or create an account, then asks the user to grant your application access. Once granted, the user is redirected back to your website or app with a special token. Less typical applications can get an authorization token by getting the username and password from a user, and making an API call using HTTP Basic Auth. Once the token is returned the application can discard the user's password, and the password should never be stored.

### Getting a token via URI redirect
There are two variations of this approach, one which requires a backend server which knows your client application secret, and another which requires no backend nor secret but instead requires a preconfigured redirect URI. The second approach is especially useful for static websites.

#### Using a client secret
**TODO**: Describe how to use a client secret with its token type

#### Using a preconfigured redirect URI

```no-highlight
https://api.malt.io/account/authorize?response_type=code&redirect_uri={website}&scope=user,recipe&client_id={client}&type=token
```

| Variable | Description                   | Example                           |
| -------- | ----------------------------- | --------------------------------- |
| website  | URL to your website's handler | http://beta.malt.io/auth/callback |
| client   | Your application token        | 51de552db0848b204b554089          |

If the user authorizes your application then the user is redirected to the `website` URL above, which contains the token in a hash value:

```no-highlight
http://your-website.com/auth/callback#access_token:5262d64b892e8d4341000001
```

Save this token and you can use it for all subsequent requests that require auth.

### Getting a token via an API call
This method of getting an authorization token **requires** that you have access to a user's username and password. Accounts that use only social login and thus do not have a password set up cannot work with this method. Users typically prefer the methods described above, because they do not require giving a third party their password. You *must not store the user's password* longer than needed to get a token.

## Authorization Token Collection [/v1/authorizations]

### List tokens [GET]
Get a list of authorization tokens for your application client ID and a specific user. **This request requires HTTP Basic Auth.** Example request:

```no-highlight
https://api.malt.io/v1/authorizations?clientId=abc123&clientSecret=some-secret
```

+ Parameters

    + clientId (required, string, `abc123`) ... The application client ID
    + clientSecret (required, string, `foo`) ... The application client secret

+ Request
    
    + Headers

            Content-Type: application/json
            Authorization: Basic ZGFuaWVsOmFiYzEyMw==

+ Response 200 (application/json)

    + Body

        [
            {
                "clientId": "abc123",
                "created": "2013-07-11T17:28:52.787Z",
                "id": "51deeb54763ce70000000001",
                "scopes": [
                    "user",
                    "recipe"
                ],
                "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
                "userId": "51de54131084ffeef8000001"
            }
        ]

### Create an authorization [POST]
Create a new authorization token with your given client ID for a given user.

+ Parameters

    + clientId (required, string, `abc123`) ... The application client ID
    + clientSecret (required, string, `foo`) ... The application client secret
    + scopes (required, array, `['user', 'recipe', 'private']`) ... A list of authorization scopes that your application requires

+ Request
    
    + Headers

            Content-Type: application/json
            Authorization: Basic ZGFuaWVsOmFiYzEyMw==

    + Body

        {
            "clientId": "abc123",
            "clientSecret": "some-secret",
            "scopes": [
                "user",
                "recipe"
            ]
        }

+ Response 201 (application/json)

    + Body

        {
            "clientId": "abc123",
            "created": "2013-07-11T17:28:52.787Z",
            "id": "51deeb54763ce70000000001",
            "scopes": [
                "user",
                "recipe"
            ],
            "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
            "userId": "51de54131084ffeef8000001"
        }

## Authorization [/v1/authorizations/{id}]
Get, update, and delete individual authorizations.

### Get authorization [GET]
Get a single authorization by its ID. The authorization must be for your application, specified in the `clientId`.

+ Parameters

    + id (required, string, `51deeb54763ce70000000001`) ... Authorization ID

+ Response 200 (application/json)

    + Body

        {
            "clientId": "abc123",
            "created": "2013-07-11T17:28:52.787Z",
            "id": "51deeb54763ce70000000001",
            "scopes": [
                "user",
                "recipe"
            ],
            "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
            "userId": "51de54131084ffeef8000001"
        }

### Update authorization [PUT]
Update a single authorization's scopes by its ID.

+ Parameters

    + id (required, string, `51deeb54763ce70000000001`) ... Authorization ID
    + clientId (required, string, `abc123`) ... The application client ID
    + clientSecret (required, string, `foo`) ... The application client secret
    + scopes (optional, array, `['user', 'recipe', 'private']`) ... A list of authorization scopes that your application requires
    + addScopes (optional, array, `['recipe:delete']`) ... A list of authorization scopes to add
    + removeScopes (optional, array, `['private']`) ... A list of authorization scopes to remove

+ Request

    + Body

        {
            "clientId": "abc123",
            "clientSecret": "some-secret",
            "addScopes": [
                "recipe:delete",
                "private"
            ]
        }

+ Response 200 (application/json)

    + Body

        {
            "clientId": "abc123",
            "created": "2013-07-11T17:28:52.787Z",
            "id": "51deeb54763ce70000000001",
            "scopes": [
                "user",
                "recipe"
            ],
            "token": "b608d4b097c838067aba07eb9206faab1bf4b446",
            "userId": "51de54131084ffeef8000001"
        }

### Delete authorization [DELETE]
Delete an authorization. Afterward the token associated with this authorization will no longer work to make authenticated API calls.

+ Response 204

# Group Recipes
Authenticated calls to get, modify and delete recipes.

## Recipe Collection [/v1/recipes]
A collection of recipes.

### Get recipes [GET]
Get a list of recipes with the given filtering and sorting parameters. By default only public recipes are returned, but the `private` parameter can be set so that private recipes are included.

+ Parameters

    + ids (optional, string, `100,102,105`) ... List of recipe IDs
    + userIds (optional, string, `200,201,204`) ... List of recipe owner user IDs
    + slugs (optional, string, `test-recipe,hefeweizen`) ... List of recipe slugs to find in conjunction with `userIds`
    + offset = `0` (optional, integer, `0`) ... Number of recipes to skip
    + limit = `20` (optional, integer, `30`) ... Number of recipes returned
    + sort = `-created` (optional, string, `name`) ... Sort method
    
        + Values
            + `created`
            + `-created`
            + `name`
            + `-name`

    + detail = `false` (optional, boolean, `true`) ... Whether to show detailed info
    + private = `false` (optional, boolean, `true`) ... If true, return private recipes of the requesting user. By default only return public recipes.

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 200

    [Recipe Collection][]

### Create a new recipe [POST]
Create a new recipe. If `private` is true, then this recipe will not show up in public recipe lists.

+ Parameters

    + private = `false` (optional, boolean, `true`) ... Make this recipe private
    + detail = `false` (optional, boolean, `true`) ... Return calculated recipe details
    + recipe (required, object, `{...}`) ... A JSON representation of a recipe

+ Request (application/json)

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

    + Body

        {
            "detail": true,
            "recipe": {
                "name": "Recipe name",
                "description": "Recipe description",
                "fermentables": [
                    {
                        "name": "Pale malt",
                        "weight": 3.5,
                        "yield": 0.75,
                        "color": 4.0
                    }
                ]
            }
        }

+ Response 200 (application/json; charset=utf-8)

    {
        "created": "2013-11-02T17:25:51.275Z", 
        "data": {
            "agingDays": 14, 
            "agingTemp": 20, 
            "agingTempF": 68, 
            "author": "Anonymous Brewer", 
            "batchSize": 20, 
            "batchSizeGallons": 5.283440000000001, 
            "boilSize": 10, 
            "boilSizeGallons": 2.6417200000000003, 
            "bottlingPressure": 2.5, 
            "bottlingTemp": 23, 
            "bottlingTempF": 73.4, 
            "description": "Just a basic beer example for testing. foo this is a long description", 
            "fermentables": [
                {
                    "color": 6.096, 
                    "late": false, 
                    "name": "Extra pale extract", 
                    "weight": 4.5, 
                    "yield": 75
                }
            ], 
            "ibuMethod": "tinseth", 
            "mash": null, 
            "mashEfficiency": 75, 
            "name": "Another Beer 2", 
            "primaryDays": 14, 
            "primaryTemp": 20, 
            "primaryTempF": 68, 
            "secondaryDays": 0, 
            "secondaryTemp": 0, 
            "secondaryTempF": 32, 
            "servingSize": 0.355, 
            "servingSizeOz": 0.09378106, 
            "spices": [
                {
                    "aa": 4.5, 
                    "form": "pellet", 
                    "name": "Cascade hops", 
                    "time": 60, 
                    "use": "boil", 
                    "weight": 0.028349556839727483
                }
            ], 
            "steepEfficiency": 50, 
            "steepTime": 20, 
            "style": null, 
            "tertiaryDays": 0, 
            "tertiaryTemp": 0, 
            "tertiaryTempF": 32, 
            "yeast": [
                {
                    "attenuation": 74, 
                    "form": "liquid", 
                    "name": "Wyeast 3052", 
                    "type": "ale"
                }
            ]
        }, 
        "id": "5275359f031555931a000005", 
        "private": false, 
        "slug": "another-beer-2", 
        "user": {
            "id": "51de54131084ffeef8000001", 
            "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
            "name": "daniel"
        }
    }

## Recipe [/v1/recipes/{id}]
A single recipe that is referenced by its ID.

+ Model

    + Headers

            Content-Type: application/json; charset=utf-8

    + Body

        {
            "created": "2013-11-02T17:25:51.275Z", 
            "data": {
                "agingDays": 14, 
                "agingTemp": 20, 
                "agingTempF": 68, 
                "author": "Anonymous Brewer", 
                "batchSize": 20, 
                "batchSizeGallons": 5.283440000000001, 
                "boilSize": 10, 
                "boilSizeGallons": 2.6417200000000003, 
                "bottlingPressure": 2.5, 
                "bottlingTemp": 23, 
                "bottlingTempF": 73.4, 
                "description": "Just a basic beer example for testing. foo this is a long description", 
                "fermentables": [
                    {
                        "color": 6.096, 
                        "late": false, 
                        "name": "Extra pale extract", 
                        "weight": 4.5, 
                        "yield": 75
                    }
                ], 
                "ibuMethod": "tinseth", 
                "mash": null, 
                "mashEfficiency": 75, 
                "name": "Another Beer 2", 
                "primaryDays": 14, 
                "primaryTemp": 20, 
                "primaryTempF": 68, 
                "secondaryDays": 0, 
                "secondaryTemp": 0, 
                "secondaryTempF": 32, 
                "servingSize": 0.355, 
                "servingSizeOz": 0.09378106, 
                "spices": [
                    {
                        "aa": 4.5, 
                        "form": "pellet", 
                        "name": "Cascade hops", 
                        "time": 60, 
                        "use": "boil", 
                        "weight": 0.028349556839727483
                    }
                ], 
                "steepEfficiency": 50, 
                "steepTime": 20, 
                "style": null, 
                "tertiaryDays": 0, 
                "tertiaryTemp": 0, 
                "tertiaryTempF": 32, 
                "yeast": [
                    {
                        "attenuation": 74, 
                        "form": "liquid", 
                        "name": "Wyeast 3052", 
                        "type": "ale"
                    }
                ]
            }, 
            "id": "5275359f031555931a000005", 
            "private": false, 
            "slug": "another-beer-2", 
            "user": {
                "id": "51de54131084ffeef8000001", 
                "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
                "name": "daniel"
            }
        }

### Get a recipe [GET]
Get a single recipe by its ID. If the recipe is private, then `private` must be set or a not found response will be returned.

+ Parameters

    + id (required, string, `100`) ... Recipe ID
    + detail = `false` (optional, boolean, `true`) ... Whether to show detailed info
    + private = `false` (optional, boolean, `true`) ... If true, return private recipes of the requesting user. By default only return public recipes.

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 200

    [Recipe][]

### Update a recipe [PUT]
Update a recipe by its ID.

+ Parameters

    + id (required, string, `100`) ... Recipe ID
    + detail = `false` (optional, boolean, `true`) ... Whether to show detailed info
    + private = `false` (optional, boolean, `true`) ... If true, return private recipes of the requesting user. By default only return public recipes.
    + recipe (required, object, `{...}`) ... A JSON representation of a recipe

+ Request (application/json)

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

    + Body

        {
            "detail": true,
            "recipe": {
                "name": "Recipe name",
                "description": "Recipe description",
                "fermentables": [
                    {
                        "name": "Pale malt",
                        "weight": 3.5,
                        "yield": 0.75,
                        "color": 4.0
                    }
                ]
            }
        }

+ Response 200

    [Recipe][]

### Delete a recipe [DELETE]
Delete a recipe by its ID.

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 204

# Group Users
Authenticated calls to get, modify and delete users.

## User Collection [/v1/users]
A collection of users.

### Get users [GET]
Get a list of users with the given filtering and sorting options. When `sort` is set to `location`, then the `fromLat` and `fromLong` parameters are **required**. Example request:

```no-highlight
https://api.malt.io/v1/users?names=user1,user2&limit=5&sort=-recipeCount
```

+ Parameters

    + ids (optional, array, `100,102,103`) ... User IDs
    + names (optional, array, `name1,name2,name3`) ... User names
    + offset = `0` (optional, integer, `0`) ... Number of users to skip
    + limit = `20` (optional, integer, `30`) ... Number of users returned
    + sort = `-created` (optional, string, `name`) ... Sort method
    
        + Values
            + `created`
            + `-created`
            + `name`
            + `-name`
            + `location`
            + `recipeCount`
            + `-recipeCount`

    + fromLat (optional, number, `47.61`) ... Latitude to use when `sort` is `location`
    + fromLong (optional, number, `-122.331`) ... Longitude to use when `sort` is `location`

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Respone 200



## User [/v1/users/{id}]
An individual user referenced by ID.

+ Model (application/json)

    {
        "confirmed": true, 
        "created": "2013-07-11T06:43:31.988Z", 
        "following": [], 
        "id": "51de54131084ffeef8000001", 
        "image": "http://www.gravatar.com/avatar/f3ada405ce890b6f8204094deb12d8a8?s=SIZE&d=retro", 
        "location": [
            -122.331, 
            47.61
        ], 
        "name": "daniel", 
        "recipeCount": 0
    }

### Get a user [GET]
Get a single user by ID.

+ Parameters

    + id (required, string, `lj23jh5jl42h3`) ... User ID

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 200

    [User][]

### Update a user [PUT]
Update a user by ID.

+ Parameters

    + id (required, number, `kl2j4h32`) ... User ID
    + name (optional, string, `username`) ... User name
    + email (optional, string, `foo@bar.com`) ... User email
    + image (optional, string, `http://...`) ... URL to a user's profile image
    + password (optional, string, `mypassword`) ... User password
    + following (optional, array, `['101', '103']`) ... List of other users to follow by user ID
    + addFollowing (optional, array, `['102']`) ... List of other users to add to the list of followed users by ID
    + removeFollowing (optional, array, `['101']`) ... List of other users to remove from the list of followed users by ID
    + location (optional, array, `[-122.331, 47.61]`) ... Array of `[longitude, latitude]` location

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 200

    [User][]

### Delete a user [DELETE]
Delete a user by ID.

+ Request

    + Headers

            Authorization: bearer 5262d64b892e8d4341000001

+ Response 204
