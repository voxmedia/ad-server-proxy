A small ad-server proxy that speeds up local development ad server requests and permits local targeting overrides and insertions. It proxies interactions with our ad serving partner [OpenX](http://openx.com/).


## Getting started

1. Download or clone this repository
2. Install the required gems via `bundle install`
3. Create your own `overrides.yml` and customize it. (To start, I would suggest copying or renaming `overrides.yml.example`)
4. Start the server `bundle exec rackup`. This starts on Sinatra's default port: 9292. _(use `-p <port number>` to start it on a different port)_

# Proxying Things

This server responds to two end points:

## 1. Javascript library proxy and rewriting

**http://localhost:9292/jstag**

_example_

```javascript
<script src="http://localhost:9292/jstag&url=http%3A%2F%2Fox-d.example.com%2Fw%2F1.0%2Fjstag" type="text/javascript"></script>
```

If you are using OpenX's javascript library to get [Multi ad unit integration](http://docs.openx.com/ad_server/#adtagguide_synchjs_struct_multi.html), the initial request to `http://d.example.com/w/1.0/jstag` should be routed through proxy, which will automatically route the request for ads through the proxy.

This will fetch OpenX's main javascript library. It updates the `fetchAds` function and caches the result, now all future ad requests will be routed through the proxy.

The updated function behaves like this. _(this is simplified to highlight the single change the proxy makes)._

```javascript
fetchAds = function() {
  var url = 'http://localhost:9292/mock?url=' + encodeURIComponent(createAdRequestURL());
  E.template(E.Templates.SCRIPT, {
    src: url
  });
  E.write()
};
```

## 2. Ad Unit Request proxy

**http://localhost:9292/mock**

_example_

```javascript
<script src="http://localhost:9292/mock&url=http://your_ad_server.domain.com/w/1.0/acj?o=1133877895&callback=OX_1373833895&ju=http%3A//this.is.fake.com%3A3000/&jr=&tid=16&pgid=13822&auid=561878%2C564363%2C463317%2C304996&c.browser_width=xlarge&res=1920x1200x24&plg=swf%2Csl%2Cqt%2Cshk%2Cpm&ch=UTF-8&tz=300&ws=1287x526&vmt=1&sd=1" type="text/javascript"></script>
```

If you are calling [OpenX stand alone ads](http://docs.openx.com/ad_server/#adtagguide_structured_structure_xml.html) , you will need to route requests through the proxy. This means appending `http://localhost:9292/mock&url=` to all requests for ads.


# Documentation

## Limitations of local ad development without this proxy

* The ad server has to have the correct targeting, and knowledge of all the ad units.
* There is also a 5-60 minute delay for any changes.
* Each request requires a round trip to get the ad data from the server.

## Development Proxy Server

To overcome these limitations here is a small proxy server that does the following:

1. Cache OpenX responses
2. Override ad units configured in a yaml file.
3. Inject ad units configured in a yaml file.

### How Does this work?

![Proxy Server](http://i.imgur.com/ZdoKD2q.png)

1. When enabled, Chorus will proxy the full ad server request to a small Sinatra app.
2. The proxy app will respond with a redis-backed cached version if this request has been made before, if not it will request this information from the ad server and cache it.
3. the proxy app then replaces or inserts any overridden ad units defined in `/overrides.yml`
4. It responds with a json string, formatted as through it was a response from the ad server.

### Benefits

* _Faster_ responses from cached version of ad server code.
* Ability to override and insert our own local ad code for development without bothering adops
* and without waiting 15-60 minutes for targeting rules to propigate

### The Override File

A simple yaml file that contains the ability to enable and disable this proxy. _note: Changing the `ad_unit` configurations can be done without restarting the server._

```yaml
enabled: true

ad_units: [
  {
    url_pattern: /verge/,
    unit_id: 563927,
    group_id: 0, # optional
    width: 300,  # optional
    height: 250, # optional
    html: '<div width="300px" height="250px"><img src="http://i.imgur.com/OsM2GBy.png"/></div>'
  }
  # ...
]
```

## Authors

* Niv Shah – [@nivshah](http://github.com/nivshah)
* Casey Kolderup – [@ckolderup](http://github.com/ckolderup)
* Clif Reeder – [@clifff](http://github.com/clifff)
* Skip Baney – [@twelvelabs](http://github.com/twelvelabs)
* Brian Anderson – [@banderson623](http://github.com/banderson623)

## Contributing

This is an active project and we encourage contributions. [Please review our guidelines and code of conduct before contributing.](https://github.com/voxmedia/open-source-contribution-guidelines)

### Testing

There are a few limited unit tests in `/test/`. These can be run by executing `bundle exec ruby ./test/ad_server_proxy_test.rb`.

## License

Copyright (c) 2014, Vox Media, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the {organization} nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
