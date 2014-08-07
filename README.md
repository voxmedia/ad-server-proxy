A Small _OpenX_ (DFP coming shortly) proxy that speeds up local development ad server requests and permits local targeting overrides and insertions.



# Up and Running

1. Download or clone this repository
2. Install the required gems via `bundle install`
3. Create your own `ad-unit-overrides.yml` and customize it. (To start, I would suggest copying or renaming `ad-unit-overrides.yml.example`)
4. Start the server `bundle exec rackup`. This starts on Sinatra's default port: 9292. _(use `-p <port number>` to start it on a different port)_

# Using it

This server responds to a single end point: `/mock&url=`. Where the URL being passed in should be what is normally called by your openx configuration. Here at Vox Media it looks something like this:

```
http://<your.ad.server.domain.com>/w/1.0/acj?o=1133877895&callback=OX_1373833895&ju=http%3A//this.is.fake.com%3A3000/&jr=&tid=16&pgid=13822&auid=561878%2C564363%2C463317%2C304996&c.browser_width=xlarge&res=1920x1200x24&plg=swf%2Csl%2Cqt%2Cshk%2Cpm&ch=UTF-8&tz=300&ws=1287x526&vmt=1&sd=1
```


## Limitations of local ad development without this proxy

* The ad server has to have the correct targeting, and knowledge of all the ad units.
* There is also a 5-60 minute delay for any changes.
* Each request requires a round trip to get the ad data from the server.


# Development Proxy Server

To overcome these limitations here is a small proxy server that does the following:

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
