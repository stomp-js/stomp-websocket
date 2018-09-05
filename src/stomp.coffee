
# **STOMP Over Web Socket** is a JavaScript STOMP Client using
# [HTML5 Web Sockets API](http://www.w3.org/TR/websockets).
#
# * Copyright (C) 2010-2012 [Jeff Mesnil](http://jmesnil.net/)
# * Copyright (C) 2012 [FuseSource, Inc.](http://fusesource.com)
# * Copyright (C) 2017 [Deepak Kumar](https://www.kreatio.com)
#
# This library supports:
#
# * [STOMP 1.0](http://stomp.github.com/stomp-specification-1.0.html)
# * [STOMP 1.1](http://stomp.github.com/stomp-specification-1.1.html)
# * [STOMP 1.2](http://stomp.github.com/stomp-specification-1.2.html)
#
# The library is accessed through the `Stomp` object that is set on the `window`
# when running in a Web browser.

###
   Stomp Over WebSocket http://www.jmesnil.net/stomp-websocket/doc/ | Apache License V2.0

   Copyright (C) 2010-2013 [Jeff Mesnil](http://jmesnil.net/)
   Copyright (C) 2012 [FuseSource, Inc.](http://fusesource.com)
   Copyright (C) 2017 [Deepak Kumar](https://www.kreatio.com)
###

# @mixin
#
# @private
Byte =
  # LINEFEED byte (octet 10)
  LF: '\x0A'
  # NULL byte (octet 0)
  NULL: '\x00'

# @see http://stomp.github.com/stomp-specification-1.2.html#STOMP_Frames STOMP Frame
#
# Frame class represents a STOMP frame
#
class Frame
  # Frame constructor. `command`, `headers` and `body` are available as properties.
  #
  # Many of the Client methods pass instance of received Frame to the callback.
  #
  # @param command [String]
  # @param headers [Object]
  # @param body [String]
  # @param escapeHeaderValues [Boolean]
  constructor: (@command, @headers={}, @body='', @escapeHeaderValues = false) ->

  # Provides a textual representation of the frame
  # suitable to be sent to the server
  #
  # @private
  toString: ->
    lines = [@command]
    skipContentLength = if (@headers['content-length'] == false) then true else false
    delete @headers['content-length'] if skipContentLength

    for own name, value of @headers
      if @escapeHeaderValues && @command != 'CONNECT' && @command != 'CONNECTED'
        lines.push("#{name}:#{Frame.frEscape(value)}")
      else
        lines.push("#{name}:#{value}")
    if @body && !skipContentLength
      lines.push("content-length:#{Frame.sizeOfUTF8(@body)}")
    lines.push(Byte.LF + @body)
    return lines.join(Byte.LF)

  # Compute the size of a UTF-8 string by counting its number of bytes
  # (and not the number of characters composing the string)
  #
  # @private
  @sizeOfUTF8: (s)->
    if s
      encodeURI(s).match(/%..|./g).length
    else
      0

  # Unmarshall a single STOMP frame from a `data` string
  #
  # @private
  unmarshallSingle= (data, escapeHeaderValues=false) ->
    # search for 2 consecutives LF byte to split the command
    # and headers from the body
    divider = data.search(///#{Byte.LF}#{Byte.LF}///)
    headerLines = data.substring(0, divider).split(Byte.LF)
    command = headerLines.shift()
    headers = {}
    # utility function to trim any whitespace before and after a string
    trim= (str) ->
      str.replace(/^\s+|\s+$/g,'')
    # Parse headers in reverse order so that for repeated headers, the 1st
    # value is used
    for line in headerLines.reverse()
      idx = line.indexOf(':')
      if escapeHeaderValues  && command != 'CONNECT' && command != 'CONNECTED'
        headers[trim(line.substring(0, idx))] = Frame.frUnEscape(trim(line.substring(idx + 1)))
      else
        headers[trim(line.substring(0, idx))] = trim(line.substring(idx + 1))
    # Parse body
    # check for content-length or  topping at the first NULL byte found.
    body = ''
    # skip the 2 LF bytes that divides the headers from the body
    start = divider + 2
    if headers['content-length']
      len = parseInt headers['content-length']
      body = ('' + data).substring(start, start + len)
    else
      chr = null
      for i in [start...data.length]
        chr = data.charAt(i)
        break if chr is Byte.NULL
        body += chr
    return new Frame(command, headers, body, escapeHeaderValues)

  # Split the data before unmarshalling every single STOMP frame.
  # Web socket servers can send multiple frames in a single websocket message.
  # If the message size exceeds the websocket message size, then a single
  # frame can be fragmented across multiple messages.
  #
  # `datas` is a string.
  #
  # returns an *array* of Frame objects
  #
  # @private
  @unmarshall: (datas, escapeHeaderValues=false) ->
    # Ugly list comprehension to split and unmarshall *multiple STOMP frames*
    # contained in a *single WebSocket frame*.
    # The data is split when a NULL byte (followed by zero or many LF bytes) is
    # found
    frames = datas.split(///#{Byte.NULL}#{Byte.LF}*///)

    r =
      frames:  []
      partial: ''
    r.frames = (unmarshallSingle(frame, escapeHeaderValues) for frame in frames[0..-2])

    # If this contains a final full message or just a acknowledgement of a PING
    # without any other content, process this frame, otherwise return the
    # contents of the buffer to the caller.
    last_frame = frames[-1..][0]

    if last_frame is Byte.LF or (last_frame.search ///#{Byte.NULL}#{Byte.LF}*$///) isnt -1
      r.frames.push(unmarshallSingle(last_frame, escapeHeaderValues))
    else
      r.partial = last_frame
    return r

  # Marshall a Stomp frame
  #
  # @private
  @marshall: (command, headers, body, escapeHeaderValues) ->
    frame = new Frame(command, headers, body, escapeHeaderValues)
    return frame.toString() + Byte.NULL

  # Escape header values
  #
  # @private
  @frEscape: (str) ->
    ("" + str).replace(/\\/g, "\\\\").replace(/\r/g, "\\r").replace(/\n/g, "\\n").replace(/:/g, "\\c")

  # Escape header values
  #
  # @private
  @frUnEscape: (str) ->
    ("" + str).replace(/\\r/g, "\r").replace(/\\n/g, "\n").replace(/\\c/g, ":").replace(/\\\\/g, "\\")

# STOMP Client Class
#
# All STOMP protocol is exposed as methods of this class (`connect()`,
# `send()`, etc.)
class Client
  # Please do not create instance of this class directly, use one of the methods {Stomp~client}, {Stomp~over}
  # or {overTCP}
  # in Stomp.
  #
  # @private
  #
  # @see Stomp
  constructor: (ws_fn) ->
    @ws_fn = ->
      ws= ws_fn()
      ws.binaryType = "arraybuffer"
      ws

    # @property reconnect_delay [Number] automatically reconnect with delay in milliseconds, set to 0 to disable
    @reconnect_delay= 0

    # used to index subscribers
    @counter = 0

    # @property [Boolean] current connection state
    @connected = false

    # @property [{outgoing: Number, incoming: Number}] outgoing and incoming
    # heartbeat in milliseconds, set to 0 to disable
    @heartbeat = {
      # send heartbeat every 10s by default (value is in ms)
      outgoing: 10000
      # expect to receive server heartbeat at least every 10s by default
      # (value in ms)
      incoming: 10000
    }
    # maximum *WebSocket* frame size sent by the client. If the STOMP frame
    # is bigger than this value, the STOMP frame will be sent using multiple
    # WebSocket frames (default is 16KiB)
    @maxWebSocketFrameSize = 16*1024
    # subscription callbacks indexed by subscriber's ID
    @subscriptions = {}
    @partialData = ''

  # By default, debug messages are logged in the window's console if it is defined.
  # This method is called for every actual transmission of the STOMP frames over the
  # WebSocket.
  #
  # It is possible to set a `debug(message)` method
  # on a client instance to handle differently the debug messages:
  #
  # @example
  #     client.debug = function(str) {
  #         // append the debug log to a #debug div
  #         $("#debug").append(str + "\n");
  #     };
  #
  # @example disable logging
  #     client.debug = function(str) {};
  #
  # @note the default can generate lot of log on the console. Set it to empty function to disable
  #
  # @param message [String]
  debug: (message) ->
    window?.console?.log message
      
  # Utility method to get the current timestamp (Date.now is not defined in IE8)
  #
  # @private
  now= ->
    if Date.now then Date.now() else new Date().valueOf
  
  # Base method to transmit any stomp frame
  #
  # @private
  _transmit: (command, headers, body) ->
    out = Frame.marshall(command, headers, body, @escapeHeaderValues)
    @debug? ">>> " + out
    # if necessary, split the *STOMP* frame to send it on many smaller
    # *WebSocket* frames
    while(true)
      if out.length > @maxWebSocketFrameSize
        @ws.send(out.substring(0, @maxWebSocketFrameSize))
        out = out.substring(@maxWebSocketFrameSize)
        @debug? "remaining = " + out.length
      else
        return @ws.send(out)

  # Heart-beat negotiation
  #
  # @private
  _setupHeartbeat: (headers) ->
    return unless headers.version in [Stomp.VERSIONS.V1_1, Stomp.VERSIONS.V1_2]

    # heart-beat header received from the server looks like:
    #
    #     heart-beat: sx, sy
    [serverOutgoing, serverIncoming] = (parseInt(v) for v in headers['heart-beat'].split(","))

    unless @heartbeat.outgoing == 0 or serverIncoming == 0
      ttl = Math.max(@heartbeat.outgoing, serverIncoming)
      @debug? "send PING every #{ttl}ms"
      # The `Stomp.setInterval` is a wrapper to handle regular callback
      # that depends on the runtime environment (Web browser or node.js app)
      @pinger = Stomp.setInterval ttl, =>
        @ws.send Byte.LF
        @debug? ">>> PING"

    unless @heartbeat.incoming == 0 or serverOutgoing == 0
      ttl = Math.max(@heartbeat.incoming, serverOutgoing)
      @debug? "check PONG every #{ttl}ms"
      @ponger = Stomp.setInterval ttl, =>
        delta = now() - @serverActivity
        # We wait twice the TTL to be flexible on window's setInterval calls
        if delta > ttl * 2
          @debug? "did not receive server activity for the last #{delta}ms"
          @ws.close()

  # parse the arguments number and type to find the headers, connectCallback and
  # (eventually undefined) errorCallback
  #
  # @private
  _parseConnect: (args...) ->
    headers = {}
    if args.length < 2
      throw("Connect requires at least 2 arguments")
    if typeof(args[1]) == 'function'
      [headers, connectCallback, errorCallback, closeEventCallback] = args
    else
      switch args.length
        when 6
          [headers.login, headers.passcode, connectCallback, errorCallback, closeEventCallback, headers.host] = args
        else
          [headers.login, headers.passcode, connectCallback, errorCallback, closeEventCallback] = args

    [headers, connectCallback, errorCallback, closeEventCallback]

  # @see http://stomp.github.com/stomp-specification-1.2.html#CONNECT_or_STOMP_Frame CONNECT Frame
  #
  # The `connect` method accepts different number of arguments and types. See the Overloads list. Use the
  # version with headers to pass your broker specific options.
  #
  # @overload connect(headers, connectCallback)
  #
  # @overload connect(headers, connectCallback, errorCallback)
  #
  # @overload connect(login, passcode, connectCallback)
  #
  # @overload connect(login, passcode, connectCallback, errorCallback)
  #
  # @overload connect(login, passcode, connectCallback, errorCallback, closeEventCallback)
  #
  # @overload connect(login, passcode, connectCallback, errorCallback, closeEventCallback, host)
  #
  # @param headers [Object]
  # @option headers [String] login
  # @option headers [String] passcode
  # @option headers [String] host virtual host to connect to. STOMP 1.2 makes it mandatory, however the broker may not mandate it
  # @param connectCallback [function(Frame)] Called upon a successful connect or reconnect
  # @param errorCallback [function(any)] Optional, called upon an error. The passed paramer may be a {Frame} or a message
  # @param closeEventCallback [function(CloseEvent)] Optional, called when the websocket is closed.
  #
  # @param login [String]
  # @param passcode [String]
  # @param host [String] Optional, virtual host to connect to. STOMP 1.2 makes it mandatory, however the broker may not mandate it
  #
  # @example
  #        client.connect('guest, 'guest', function(frame) {
  #          client.debug("connected to Stomp");
  #          client.subscribe(destination, function(message) {
  #            $("#messages").append("<p>" + message.body + "</p>\n");
  #          });
  #        });
  #
  # @note When auto reconnect is active, `connectCallback` and `errorCallback` will be called on each connect or error
  connect: (args...) ->
    @escapeHeaderValues = false
    out = @_parseConnect(args...)
    [@headers, @connectCallback, @errorCallback, @closeEventCallback] = out

    # Indicate that this connection is active (it will keep trying to connect)
    @_active = true

    @_connect()

  # Refactored to make it callable multiple times, useful for reconnecting
  #
  # @private
  _connect: ->
    headers = @headers
    errorCallback = @errorCallback
    closeEventCallback = @closeEventCallback

    unless @_active
      @debug 'Client has been marked inactive, will not attempt to connect'
      return

    @debug? "Opening Web Socket..."

    # Get the actual Websocket (or a similar object)
    @ws= @ws_fn()

    UTF8ArrayToStr = (array) =>
      out = ""
      len = array.length
      i = 0
      while(i < len)
        c = array[i++]
        switch(c >> 4)
          when 0,1,2,3,4,5,6,7
            # 0xxxxxxx
            out += String.fromCharCode(c)
          when 12,13
            # 110x xxxx   10xx xxxx
            char2 = array[i++]
            out += String.fromCharCode(((c & 0x1F) << 6) | (char2 & 0x3F))
          when 14
            # 1110 xxxx  10xx xxxx  10xx xxxx
            char2 = array[i++]
            char3 = array[i++]
            out += String.fromCharCode(((c & 0x0F) << 12) | ((char2 & 0x3F) << 6) | ((char3 & 0x3F) << 0))
      return out

    @ws.onmessage = (evt) =>
      data = if typeof(ArrayBuffer) != 'undefined' and evt.data instanceof ArrayBuffer
        # the data is stored inside an ArrayBuffer, we decode it to get the
        # data as a String
        arr = new Uint8Array(evt.data)
        @debug? "--- got data length: #{arr.length}"
        # Return a string formed by all the char codes stored in the Uint8array
        #(String.fromCharCode(c) for c in arr).join('')
        UTF8ArrayToStr(arr)
      else
        # take the data directly from the WebSocket `data` field
        evt.data
      @serverActivity = now()
      if data == Byte.LF # heartbeat
        @debug? "<<< PONG"
        return
      @debug? "<<< #{data}"
      # Handle STOMP frames received from the server
      # The unmarshall function returns the frames parsed and any remaining
      # data from partial frames.
      unmarshalledData = Frame.unmarshall(@partialData + data, @escapeHeaderValues)
      @partialData = unmarshalledData.partial
      for frame in unmarshalledData.frames
        switch frame.command
          # [CONNECTED Frame](http://stomp.github.com/stomp-specification-1.2.html#CONNECTED_Frame)
          when "CONNECTED"
            @debug? "connected to server #{frame.headers.server}"
            @connected = true
            @version = frame.headers.version;
            # STOMP version 1.2 needs header values to be escaped
            if @version == Stomp.VERSIONS.V1_2
              @escapeHeaderValues = true

            # If a disconnect was requested while I was connecting, issue a disconnect
            unless @_active
              @disconnect()
              return

            @_setupHeartbeat(frame.headers)
            @connectCallback? frame
          # [MESSAGE Frame](http://stomp.github.com/stomp-specification-1.2.html#MESSAGE)
          when "MESSAGE"
            # the `onreceive` callback is registered when the client calls
            # `subscribe()`.
            # If there is registered subscription for the received message,
            # we used the default `onreceive` method that the client can set.
            # This is useful for subscriptions that are automatically created
            # on the browser side (e.g. [RabbitMQ's temporary
            # queues](http://www.rabbitmq.com/stomp.html)).
            subscription = frame.headers.subscription
            onreceive = @subscriptions[subscription] or @onreceive
            if onreceive
              client = this
              if (@version == Stomp.VERSIONS.V1_2)
                messageID = frame.headers["ack"]
              else
                messageID = frame.headers["message-id"]
              # add `ack()` and `nack()` methods directly to the returned frame
              # so that a simple call to `message.ack()` can acknowledge the message.
              frame.ack = (headers = {}) =>
                client .ack messageID , subscription, headers
              frame.nack = (headers = {}) =>
                client .nack messageID, subscription, headers
              onreceive frame
            else
              @debug? "Unhandled received MESSAGE: #{frame}"
          # [RECEIPT Frame](http://stomp.github.com/stomp-specification-1.2.html#RECEIPT)
          #
          # The client instance can set its `onreceipt` field to a function taking
          # a frame argument that will be called when a receipt is received from
          # the server:
          #
          #     client.onreceipt = function(frame) {
          #       receiptID = frame.headers['receipt-id'];
          #       ...
          #     }
          when "RECEIPT"
          # if this is the receipt for a DISCONNECT, close the websocket
            if (frame.headers["receipt-id"] == @closeReceipt)
              # Discard the onclose callback to avoid calling the errorCallback when
              # the client is properly disconnected.
              @ws.onclose = null
              @ws.close()
              @_cleanUp()
              @_disconnectCallback?()
            else
              @onreceipt?(frame)
          # [ERROR Frame](http://stomp.github.com/stomp-specification-1.2.html#ERROR)
          when "ERROR"
            errorCallback?(frame)
          else
            @debug? "Unhandled frame: #{frame}"
    @ws.onclose   = (closeEvent) =>
      msg = "Whoops! Lost connection to #{@ws.url}"
      @debug?(msg)
      closeEventCallback?(closeEvent)
      @_cleanUp()
      errorCallback?(msg)
      @_schedule_reconnect()

    @ws.onopen    = =>
      @debug?('Web Socket Opened...')
      headers["accept-version"] = Stomp.VERSIONS.supportedVersions()
      headers["heart-beat"] = [@heartbeat.outgoing, @heartbeat.incoming].join(',')
      @_transmit "CONNECT", headers

  #
  # @private
  _schedule_reconnect: ->
    if @reconnect_delay > 0
      @debug?("STOMP: scheduling reconnection in #{@reconnect_delay}ms")
      # setTimeout is available in both Browser and Node.js environments
      @_reconnector = setTimeout(=>
        if @connected
          @debug?('STOMP: already connected')
        else
          @debug?('STOMP: attempting to reconnect')
          @_connect()
      , @reconnect_delay)

  # @see http://stomp.github.com/stomp-specification-1.2.html#DISCONNECT DISCONNECT Frame
  #
  # Disconnect from the STOMP broker. To ensure graceful shutdown it sends a DISCONNECT Frame
  # and wait till the broker acknowledges.
  #
  # disconnectCallback will be called only if the broker was actually connected.
  #
  # @param disconnectCallback [function()]
  # @param headers [Object] optional
  disconnect: (disconnectCallback, headers={}) ->
    @_disconnectCallback = disconnectCallback

    # indicate that auto reconnect loop should terminate
    @_active = false

    if @connected
      unless headers.receipt
        headers.receipt = "close-" + @counter++
      @closeReceipt = headers.receipt
      try
        @_transmit "DISCONNECT", headers
      catch error
        @debug?('Ignoring error during disconnect', error)

  # Clean up client resources when it is disconnected or the server did not
  # send heart beats in a timely fashion
  #
  # @private
  _cleanUp: () ->
    # Clear if a reconnection was scheduled
    clearTimeout @_reconnector if @_reconnector

    @connected = false
    @subscriptions = {}
    @partial = ''
    Stomp.clearInterval @pinger if @pinger
    Stomp.clearInterval @ponger if @ponger

  # @see http://stomp.github.com/stomp-specification-1.2.html#SEND SEND Frame
  #
  # Send a message to a named destination. Refer to your STOMP broker documentation for types
  # and naming of destinations. The headers will, typically, be available to the subscriber.
  # However, there may be special purpose headers corresponding to your STOMP broker.
  #
  # @param destination [String] mandatory
  # @param headers [Object] Optional
  # @param body [String] Optional
  #
  # @example
  #     client.send("/queue/test", {priority: 9}, "Hello, STOMP");
  #
  # @example payload without headers
  #     # If you want to send a message with a body, you must also pass the headers argument.
  #     client.send("/queue/test", {}, "Hello, STOMP");
  #
  # @note Body must be String. You will need to covert the payload to string in case it is not string (e.g. JSON)
  send: (destination, headers={}, body='') ->
    headers.destination = destination
    @_transmit "SEND", headers, body

  # @see http://stomp.github.com/stomp-specification-1.2.html#SUBSCRIBE SUBSCRIBE Frame
  #
  # Subscribe to a STOMP Broker location. The return value is an Object with unsubscribe method.
  #
  # @example
  #    callback = function(message) {
  #      // called when the client receives a STOMP message from the server
  #      if (message.body) {
  #        alert("got message with body " + message.body)
  #      } else
  #      {
  #        alert("got empty message");
  #      }
  #    });
  #
  #  var subscription = client.subscribe("/queue/test", callback);
  #
  # @example Explicit subscription id
  #      var mysubid = 'my-subscription-id-001';
  #      var subscription = client.subscribe(destination, callback, { id: mysubid });
  #
  # @param destination [String]
  # @param callback [function(message)]
  # @param headers [Object] optional
  # @return [Object] this object has a method to `unsubscribe`
  #
  # @note The library will generate an unique ID if there is none provided in the headers. To use your own ID, pass it using the headers argument
  subscribe: (destination, callback, headers={}) ->
    # for convenience if the `id` header is not set, we create a new one for this client
    # that will be returned to be able to unsubscribe this subscription
    unless headers.id
      headers.id = "sub-" + @counter++
    headers.destination = destination
    @subscriptions[headers.id] = callback
    @_transmit "SUBSCRIBE", headers
    client = this
    return {
      id: headers.id

      unsubscribe: (hdrs) ->
        client.unsubscribe headers.id, hdrs
    }

  # @see http://stomp.github.com/stomp-specification-1.2.html#UNSUBSCRIBE UNSUBSCRIBE Frame
  #
  # It is preferable to unsubscribe from a subscription by calling
  # `unsubscribe()` directly on the object returned by `client.subscribe()`:
  #
  # @example
  #     var subscription = client.subscribe(destination, onmessage);
  #     ...
  #     subscription.unsubscribe();
  #
  # @param id [String]
  # @param headers [Object] optional
  unsubscribe: (id, headers={}) ->
    delete @subscriptions[id]
    headers.id = id
    @_transmit "UNSUBSCRIBE", headers

  # @see http://stomp.github.com/stomp-specification-1.2.html#BEGIN BEGIN Frame
  #
  # Start a transaction, the returned Object has methods - `commit` and `abort`
  #
  # @param transaction_id [String] optional
  # @return [Object] member, `id` - transaction id, methods `commit` and `abort`
  #
  # @note If no transaction ID is passed, one will be created automatically
  begin: (transaction_id) ->
    txid = transaction_id || "tx-" + @counter++
    @_transmit "BEGIN", {
      transaction: txid
    }
    client = this
    return {
      id: txid
      commit: ->
        client.commit txid
      abort: ->
        client.abort txid
    }
  
  # @see http://stomp.github.com/stomp-specification-1.2.html#COMMIT COMMIT Frame
  #
  # Commit a transaction.
  # It is preferable to commit a transaction by calling `commit()` directly on
  # the object returned by `client.begin()`:
  #
  # @param transaction_id [String]
  #
  # @example
  #     var tx = client.begin(txid);
  #     ...
  #     tx.commit();
  commit: (transaction_id) ->
    @_transmit "COMMIT", {
      transaction: transaction_id
    }
  
  # @see http://stomp.github.com/stomp-specification-1.2.html#ABORT ABORT Frame
  #
  # Abort a transaction.
  # It is preferable to abort a transaction by calling `abort()` directly on
  # the object returned by `client.begin()`:
  #
  # @param transaction_id [String]
  #
  # @example
  #     var tx = client.begin(txid);
  #     ...
  #     tx.abort();
  abort: (transaction_id) ->
    @_transmit "ABORT", {
      transaction: transaction_id
    }
  
  # @see http://stomp.github.com/stomp-specification-1.2.html#ACK ACK Frame
  #
  # ACK a message. It is preferable to acknowledge a message by calling `ack()` directly
  # on the message handled by a subscription callback:
  #
  # @example
  #     client.subscribe(destination,
  #       function(message) {
  #         // process the message
  #         // acknowledge it
  #         message.ack();
  #       },
  #       {'ack': 'client'}
  #     );
  #
  # @param messageID [String]
  # @param subscription [String]
  # @param headers [Object] optional
  ack: (messageID, subscription, headers = {}) ->
    if (@version == Stomp.VERSIONS.V1_2)
      headers["id"] = messageID
    else
      headers["message-id"] = messageID
    headers.subscription = subscription
    @_transmit "ACK", headers

  # @see http://stomp.github.com/stomp-specification-1.2.html#NACK NACK Frame
  #
  # NACK a message. It is preferable to nack a message by calling `nack()` directly on the
  # message handled by a subscription callback:
  #
  # @example
  #     client.subscribe(destination,
  #       function(message) {
  #         // process the message
  #         // an error occurs, nack it
  #         message.nack();
  #       },
  #       {'ack': 'client'}
  #     );
  #
  # @param messageID [String]
  # @param subscription [String]
  # @param headers [Object] optional
  nack: (messageID, subscription, headers = {}) ->
    if (@version == Stomp.VERSIONS.V1_2)
      headers["id"] = messageID
    else
      headers["message-id"] = messageID
    headers.subscription = subscription
    @_transmit "NACK", headers

# Stomp exposes methods to instantiate Client.
#
# @mixin
Stomp =
  # @private
  VERSIONS:
    V1_0: '1.0'
    V1_1: '1.1'
    V1_2: '1.2'

    # Versions of STOMP specifications supported
    supportedVersions: ->
      '1.2,1.1,1.0'

  # This method creates a WebSocket client that is connected to
  # the STOMP server located at the url.
  #
  # @example
  #        var url = "ws://localhost:61614/stomp";
  #        var client = Stomp.client(url);
  #
  # @param url [String]
  client: (url, protocols = ['v10.stomp', 'v11.stomp', 'v12.stomp']) ->
    # This is a hack to allow another implementation than the standard
    # HTML5 WebSocket class.
    #
    # It is possible to use another class by calling
    #
    #     Stomp.WebSocketClass = MozWebSocket
    #
    # *prior* to call `Stomp.client()`.
    #
    # This hack is deprecated and  `Stomp.over()` method should be used
    # instead.

    # See remarks on the function Stomp.over
    ws_fn= ->
      klass = Stomp.WebSocketClass || WebSocket
      new klass(url, protocols)

    new Client ws_fn

  # This method is an alternative to `Stomp.client()` to let the user
  # specify the WebSocket to use (either a standard HTML5 WebSocket or
  # a similar object).
  #
  # In order to support reconnection, the function Client._connect should be callable more than once. While reconnecting
  # a new instance of underlying transport (TCP Socket, WebSocket or SockJS) will be needed. So, this function
  # alternatively allows passing a function that should return a new instance of the underlying socket.
  #
  # @example
  #         var client = Stomp.over(function(){
  #           return new WebSocket('ws://localhost:15674/ws')
  #         });
  #
  # @param ws [WebSocket|function()] a WebSocket like Object or a function returning a WebObject or similar Object
  #
  # @note If you need auto reconnect feature you must pass a function that returns a WebSocket or similar Object
  over: (ws) ->
    ws_fn = if typeof(ws) == "function" then ws else -> ws

    new Client ws_fn

  # For testing purpose, expose the Frame class inside Stomp to be able to
  # marshall/unmarshall frames
  Frame: Frame

# Timer function
#
# @private
Stomp.setInterval= (interval, f) ->
  setInterval f, interval

# @private
Stomp.clearInterval= (id) ->
  clearInterval id

# # `Stomp` object exportation

# export as CommonJS module
if exports?
  exports.Stomp = Stomp

# export in the Web Browser
if window?
  window.Stomp = Stomp
# or in the current object (e.g. a WebWorker)
else if !exports
  self.Stomp = Stomp

