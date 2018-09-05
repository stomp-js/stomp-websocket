QUnit.module("Stomp Message");

QUnit.test("Send and receive a message", function (assert) {
  var done = assert.async();

  var body = Math.random();

  var client = stompClient();
  client.debug = TEST.debug;
  client.connect(TEST.login, TEST.password,
    function () {
      client.subscribe(TEST.destination, function (message) {
        assert.equal(message.body, body);
        client.disconnect();

        done();
      });

      client.send(TEST.destination, {}, body);
    });
});

QUnit.test("Send and receive a message with a JSON body", function (assert) {
  var done = assert.async();

  var client = stompClient();
  var payload = { text: "hello", bool: true, value: Math.random() };

  client.connect(TEST.login, TEST.password,
    function () {
      client.subscribe(TEST.destination, function (message) {
        var res = JSON.parse(message.body);
        assert.equal(res.text, payload.text);
        assert.equal(res.bool, payload.bool);
        assert.equal(res.value, payload.value);
        client.disconnect();

        done();
      });

      client.send(TEST.destination, {}, JSON.stringify(payload));
    });
});

QUnit.test("Send and receive a message with a multi-byte UTF8 string", function (assert) {
  var done = assert.async();

  var client = stompClient();
  var payload = "Älä sinä yhtään and السابق";

  client.connect(TEST.login, TEST.password,
    function () {
      client.subscribe(TEST.destination, function (message) {
        assert.equal(message.body, payload);
        client.disconnect();

        done();
      });

      client.send(TEST.destination, {}, payload);
    });
});
