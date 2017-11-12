// Copyright (C) 2013 [Jeff Mesnil](http://jmesnil.net/)
//
//   Stomp Over WebSocket http://www.jmesnil.net/stomp-websocket/doc/ | Apache License V2.0
//
// The library can be used in node.js app to connect to STOMP brokers over TCP 
// or Web sockets.

// Root of the `stompjs module`

var Stomp = require('./lib/stomp.js');
module.exports = Stomp.Stomp;

module.exports.over = Stomp.Stomp.over;
module.exports.client = Stomp.Stomp.client;

if (typeof WebSocket !== 'function') {
  Stomp.Stomp.WebSocketClass = require('websocket').w3cwebsocket;
}
