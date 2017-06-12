QUnit.module("Stomp Reconnect");

/* During this test, as soon as Stomp connection is established for the first time, we force
 * disconnect by closing the underlying Websocket. We expect the reconnection logic to come into
 * force and reconnect.
 */
QUnit.test("Reconnect", function (assert) {
  var done = assert.async();

  var num_try = 1;
  var client = stompClient();
  client.reconnect_delay = 300;
  client.debug = TEST.debug;

  client.connect(TEST.login, TEST.password,
    function () {
      assert.equal(client.connected, true);

      // when connected for the first time, we close the Websocket to force disconnect
      if (num_try === 1) {
        client.ws.close();
      }

      num_try++;
    });

  setTimeout(function () {
    // in 200 ms the client should be disconnected
    assert.equal(client.connected, false);
  }, 200);

  setTimeout(function () {
    // in 1000 ms the client should be connected again
    assert.equal(client.connected, true);
    client.disconnect();

    done();
  }, 1000);

});
