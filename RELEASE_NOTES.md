# Release Notes

## 3.0 (2016/03/29)

### STOMP 1.2 and RabbitMQ support

* deletion of durable subscriptions
* STOMP 1.2 ack/nack headers

### API change

* the `unsubscribe()` method returned by `subscribe()` now takes an optional
 `headers` argument which can be used to pass headers like `durable:true` and
 `auto-delete:false` required by RabbitMQ to delete durable subscriptions

* for STOMP 1.2, `ack()` and `nack()` methods send an `id` header rather than
 a `message-id` header to match the incoming MESSAGE frame.

## 2.0 (2012/11/29)

### STOMP 1.1 support

* heart-beat
* nack
* content-length

### API change

* the `errorCallback` passed to the `connect()` method is no longer called when the
  client is properly disconnected by calling `disconnect()`.

* ack() method takes 3 parameters:
  * `messageID` & `subscription` are MANDATORY.
  * `headers` is OPTIONAL

* the `client` object has a `heartbeat` field which can be used to configure heart-beating by changing its `incoming` and `outgoing` integer fields (default value for both is 10000ms):

    client.heartbeat.outgoing = 20000 // client will send heartbeats every 20000ms
    client.heartbeat.incoming = 0 // client does not want to receive heartbeats
                                  // from the server

### Minified version

In addition to the regular `stomp.js` file, the library is also available in a minified version `stomp.min.js`

### Annotated source

The source is now [documented](http://jmesnil.net/stomp-websocket/stomp.html) :)
