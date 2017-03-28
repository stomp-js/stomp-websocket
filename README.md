# STOMP.js

This library provides a STOMP client for Web browser (using Web Sockets) or node.js applications (either using raw TCP sockets or Web Sockets).

# Project Status - Time to create a new home

This project is no longer maintained by its original author 
(http://jmesnil.net/weblog/2015/09/04/stepping-out-from-personal-open-source-projects/). However seeing the
number of forks, this project deserves coordinated effort to keep maintained. Invitations are being sent to
anyone who seems to have made changes to this project. If you need are willing to contribute please make a request.

Meanwhile check the https://github.com/stomp-js/stomp-websocket/issues to see currently planned work.

Most important probably is Auto Reconnect: https://github.com/ThoughtWire/stomp-websocket/compare/master...stomp-js:reconnect

# Change history

April 1, 2016
* Issue #1: Add support for deleting durable subscriptions
* Issue #2: Add support for STOMP 1.2
* Issue #3: Wait for DISCONNECT receipt before closing web socket

## Web Browser support

The library file is located in `lib/stomp.js` (a minified version is available in `lib/stomp.min.js`).
It does not require any dependency (except WebSocket support from the browser or an alternative to WebSocket!)

Online [documentation][doc] describes the library API (including the [annotated source code][annotated]).

### Updating older code to support auto reconnect

If you were creating your stomp client using Stomp.client

```javascript
    var url = "ws://localhost:61614/stomp";
    var client = Stomp.client(url);
    
    // Add the following if you need automatic reconnect (delay is in milli seconds)
    client.reconnect_delay = 500;
```

If you were using Stomp.over like:

```javascript
    <script src="http://cdn.sockjs.org/sockjs-0.3.min.js"></script>
    <script>
        // use SockJS implementation instead of the browser's native implementation
        var ws = new SockJS(url);
        var client = Stomp.over(ws);
        [...]
    </script>
```

Change it to:

```javascript
    <script src="http://cdn.sockjs.org/sockjs-0.3.min.js"></script>
    <script>
        // use SockJS implementation instead of the browser's native implementation
        var client = Stomp.over(function(){
                                   return new SockJS(url);
                                });
    
        // Add the following if you need automatic reconnect (delay is in milli seconds)
        client.reconnect_delay = 500;
        [...]
    </script>
```

Notes:

* After each connect (i.e., initial connect as well each reconnection) the connectCallback
  will be called.
* After reconnecting, it will not automatically subscribe to queues that were subscribed.
  So, if all subscriptions are part of the connectCallback (which it would in most of the cases),
  you will not need to do any additional handling.

## node.js support

Install the 'stompjs' module

    $ npm install @stomp-js/stompjs

In the node.js app, require the module with:

    var Stomp = require('stompjs');

To connect to a STOMP broker over a TCP socket, use the `Stomp.overTCP(host, port)` method:

    var client = Stomp.overTCP('localhost', 61613);

To connect to a STOMP broker over a WebSocket, use instead the `Stomp.overWS(url)` method:

    var client = Stomp.overWS('ws://localhost:61614');

## Development Requirements

For development (testing, building) the project requires node.js. This allows us to run tests without the browser continuously during development (see `cake watch`).

    $ npm install

## Building and Testing

[![Build Status](https://secure.travis-ci.org/jmesnil/stomp-websocket.png)](http://travis-ci.org/jmesnil/stomp-websocket)

To build JavaScript from the CoffeeScript source code:

    $ cake build

To run tests:

    $ cake test

To continuously run tests on file changes:

    $ cake watch


## Browser Tests

* Make sure you have a running STOMP broker which supports the WebSocket protocol
 (see the [documentation][doc])
* Open in your web browser the project's [test page](browsertests/index.html)
* Check all tests pass

## Use

The project contains examples for using stomp.js
to send and receive STOMP messages from a server directly in the Web Browser or in a WebWorker.

## Authors

 * [Jeff Mesnil](http://jmesnil.net/)
 * [Jeff Lindsay](http://github.com/progrium)
 * [Vanessa Williams](http://github.com/fridgebuzz)
 * [Deepak Kumar](https://github.com/kum-deepak)

[doc]: http://jmesnil.net/stomp-websocket/doc/
[annotated]: http://jmesnil.net/stomp-websocket/doc/stomp.html
