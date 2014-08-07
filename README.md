A Small OpenX proxy that speeds up local development ad server requests and permits local targeting overrides and insertions.


## Drawbacks

* The ad server has to have the correct targeting, and knowledge of all the ad units. 
* There is also a 5-60 minute delay for any changes to this.
* Each request requires a round trip to get ad info from the server.


# Development Proxy Server

To overcome these limitations there is a small proxy server that does the following:

1. Cache OpenX responses
2. Override ad units configured in a yaml file.
3. Inject ad units configured in a yaml file.

## So How Does this work?

![Proxy Server](http://i.imgur.com/ZdoKD2q.png)

1. When enabled, Chorus will proxy the full ad server request to a small Sinatra app.
2. The proxy app will respond with a redis-backed cached version if this request has been made before, if not it will request this information from the ad server and cache it.
3. the proxy app then replaces or inserts any overridden ad units defined in `/config/ad-unit-overrides.yml`
4. It responds with a json string, formatted as through it was a response from the ad server.

## Benefits

* _Faster_ responses from cached version of ad server code.
* Ability to override and insert our own local ad code for development without bothering adops
* and without waiting 15-60 minutes for targeting rules to propigate

## The Override File

A simple yaml file that contains the ability to enable and disable this proxy. _note: changing the `enabled` state requires restarting the chorus server. Changing the `ad_unit` configuration can be done without restarting chorus._

```yaml
enabled: true

ad_units: [
  {
    url_pattern: /verge/,
    unit_id: 563927,
    group_id: 0,
    width: 300,
    height: 250,
    html: '<div width="300px" height="250px"><img src="http://i.imgur.com/OsM2GBy.png"/></div>'
  }
  # ...
]
```