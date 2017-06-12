(function () {
  QUnit.module("Parse connect method arguments", {

    beforeEach: function (assert) {
      // prepare something for all following tests
      myConnectCallback = function () {
        // called back when the client is connected to STOMP broker
      };

      myErrorCallback = function () {
        // called back if the client can not connect to STOMP broker
      };

      // This only needs to be tested with ws: URL format
      client = Stomp.client(TEST.url);

      checkArgs = function (args, expectedHeaders, expectedConnectCallback, expectedErrorCallback) {
        var headers = args[0];
        var connectCallback = args[1];
        var errorCallback = args[2];

        assert.deepEqual(headers, expectedHeaders);
        assert.strictEqual(connectCallback, expectedConnectCallback);
        assert.strictEqual(errorCallback, expectedErrorCallback);
      }
    }
  });

  QUnit.test("connect(login, passcode, connectCallback)", function (assert) {
    checkArgs(
      client._parseConnect("jmesnil", "wombats", myConnectCallback),

      {login: 'jmesnil', passcode: 'wombats'},
      myConnectCallback,
      undefined);
  });

  QUnit.test("connect(login, passcode, connectCallback, errorCallback)", function (assert) {
    checkArgs(
      client._parseConnect("jmesnil", "wombats", myConnectCallback, myErrorCallback),

      {login: 'jmesnil', passcode: 'wombats'},
      myConnectCallback,
      myErrorCallback);
  });

  QUnit.test("connect(login, passcode, connectCallback, errorCallback, vhost)", function (assert) {
    checkArgs(
      client._parseConnect("jmesnil", "wombats", myConnectCallback, myErrorCallback, "myvhost"),

      {login: 'jmesnil', passcode: 'wombats', host: 'myvhost'},
      myConnectCallback,
      myErrorCallback);
  });

  QUnit.test("connect(headers, connectCallback)", function (assert) {
    var headers = {login: 'jmesnil', passcode: 'wombats', host: 'myvhost'};

    checkArgs(
      client._parseConnect(headers, myConnectCallback),

      headers,
      myConnectCallback,
      undefined);
  });

  QUnit.test("connect(headers, connectCallback, errorCallback)", function (assert) {
    var headers = {login: 'jmesnil', passcode: 'wombats', host: 'myvhost'};

    checkArgs(
      client._parseConnect(headers, myConnectCallback, myErrorCallback),

      headers,
      myConnectCallback,
      myErrorCallback);
  });
})();
