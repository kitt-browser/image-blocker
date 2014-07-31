serverRootUri = 'http://127.0.0.1:8000'
mochaPhantomJsTestRunner = serverRootUri + '/build/html/test.html'

module.exports =
  connect:
    server:
      options:
        port: 8000
        base: '.'

  mocha_phantomjs:
    all:
      options:
        urls: [
          mochaPhantomJsTestRunner
        ]
