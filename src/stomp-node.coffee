# * Copyright (C) 2013 [Jeff Mesnil](http://jmesnil.net/)
#
# The library can be used in node.js app to connect to STOMP brokers over TCP
# or Web sockets.

###
   Stomp Over WebSocket http://www.jmesnil.net/stomp-websocket/doc/ | Apache License V2.0

   Copyright (C) 2013 [Jeff Mesnil](http://jmesnil.net/)
###

Stomp = require('./stomp')

# wrap a TCP socket (provided by node.js's net module) in a "Web Socket"-like
# object
#
# @private
#
# @nodoc
wrapTCP = (port, host) ->

  # the raw TCP socket
  socket = null

  # the "Web Socket"-like object expected by stomp.js
  ws = {
    url: 'tcp://' + host + ':' + port
    send: (d) -> socket.write(d)
    close: -> socket.end()
  }

  socket = require('net').connect port, host, (e) -> ws.onopen()
  socket.on 'error', (e) -> ws.onclose?(e)
  socket.on 'close', (e) -> ws.onclose?(e)
  socket.on 'data', (data) ->
    event = {
      'data': data.toString()
    }
    ws.onmessage(event)

  return ws

# wrap a Web Socket connection (provided by the websocket npm module) in a "Web
# Socket"-like object
#
# @private
#
# @nodoc
wrapWS = (url) ->

  WebSocketClient = require('websocket').client

  # the underlying connection that will be wrapped
  connection = null

  # the "Web Socket"-like object expected by stomp.js
  ws = {
    url: url
    send: (d) -> connection.sendUTF(d)
    close: ->connection.close()
  }

  socket = new WebSocketClient()
  socket.on 'connect', (conn) ->
    connection = conn
    ws.onopen()
    connection.on 'error', (error) -> ws.onclose?(error)
    connection.on 'close', -> ws.onclose?()
    connection.on 'message', (message) ->
      if message.type == 'utf8'
        event = {
          'data': message.utf8Data
        }
        ws.onmessage(event)

  socket.connect url
  return ws

# This method can be used by node.js app to connect to a STOMP broker over a
# TCP socket
#
# @param host [String]
# @param port [Number]
overTCP = (host, port) ->
  socketFn = -> wrapTCP port, host
  Stomp.Stomp.over socketFn

# This method can be used by node.js app to connect to a STOMP broker over a
# Web socket. This accepts same format as {Stomp~client}.
#
# This method is superseded by {Stomp~client}.
#
# @deprecated
#
# @param url [String]
overWS = (url) ->
  socketFn = -> wrapWS url
  Stomp.Stomp.over socketFn

# @private
#
# @nodoc
exports.overTCP = overTCP

# @private
#
# @nodoc
exports.overWS = overWS
