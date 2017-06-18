# node.js Alternate Configurations

## Deprecation Warning

Older versions of this library required different mechanism to instantiate
the Client object in nodejs than Web Browsers. In recent versions that is no 
longer the case. Please refer [Usage](Usage.md) for suggested way to use
Stomp JS.

If you are already using one of the techniques mentioned in this page and will
like to upgrade please refer to [Upgrade](Upgrade.md).

Code for these methods are not actively maintained. These have some known
issues that can hang the node environment on certain types connectivity failures.

## Stomp.overTCP

_This connects over STOMP protocol, unlike other methods in this library which
connect using STOMP over WebSocket._

* Add npm modules `@stomp/stompjs` and `net` to your project.
  * using `npm`
    ```bash
    $ npm install @stomp/stompjs net --save
    ```
  * using `yarn`
    ```bash
    $ yarn add @stomp/stompjs net
    ```

* Require the module

    ```javascript
    var Stomp = require('@stomp/stompjs');
    ```
* To instantiate the client use `Stomp.overTCP(host, port)` method:

    ```javascript
    var client = Stomp.overTCP('localhost', 61613);
    ```
* Please note you need to pass the STOMP port of the broker.

## Stomp.overWS

* Add npm modules `@stomp/stompjs` and `websocket` to your project.
  * using `npm`
    ```bash
    $ npm install @stomp/stompjs websocket --save
    ```
  * using `yarn`
    ```bash
    $ yarn add @stomp/stompjs websocket
    ```

* Require the module

    ```javascript
    var Stomp = require('@stomp/stompjs');
    ```
* To instantiate the client use `Stomp.overWS(url)` method:

    ```javascript
    var client = Stomp.overWS('ws://localhost:15674/ws');
    ```

## What Next

Apart from this initialization, the STOMP API remains the same. Please refer to
[Usage](Usage.md).