# Change Log

## 3.1.2 (2017/11/04)

* Header value escaping as per STOMP 1.2 standard.

## 3.1.0 (2017/07/05)

* Updated tests to QUint latest version. Now using same set of tests
  for NodeJS environment.
* Pruned files and folders no longer needed.
* Updated dependencies.
* Updated build scripts.
* Refactored entire documentation.
* Enabled Travis CI (it runs all test cases using NodeJS).
* Documentation is hosted at GitHub pages.
* Updated TypeScript type definitions.

## 2.5.1 (2017/03/28)

* Added typescript definitions. Thanks Jimi Charalampidis (https://github.com/jimic)
* Published on npmjs.com.

## 2.5.0 (2017/02/15)

* Support for auto reconnect
* Minor documentation changes

## 2.4.9 (2016/04/01)

### STOMP 1.2 and RabbitMQ support

* deletion of durable subscriptions
* STOMP 1.2 ack/nack headers
* graceful shutdown

### API change

* the `unsubscribe()` method returned by `subscribe()` now takes an optional
 `headers` argument which can be used to pass headers like `durable:true` and
 `auto-delete:false` required by RabbitMQ to delete durable subscriptions

* for STOMP 1.2, `ack()` and `nack()` methods send an `id` header rather than
 a `message-id` header to match the incoming MESSAGE frame.

* although the `disconnectCallback` is still called immediately after transmitting
a DISCONNECT frame, the websocket is not closed by the client until a RECEIPT is
received. Note that due to server-side behaviour with respect to connection lingering
the RECEIPT may never be received and the socket will be closed by the server.
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
