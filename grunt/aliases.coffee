module.exports = (grunt) -> {
  default: [
    'clean'
    'copy'
    'browserify:libs'
    'browserify:dist'
    'crx:main'
    'notify:build_complete'
  ]


  dev: [
    'clean'
    'connect:testing:server'
    'copy'

    'browserify:libs'
    'browserify:test'
    'browserify:dev'

    'mocha_phantomjs'
    'notify:build_complete'

    'watch'
  ]

  test: [
    'mocha_phantomjs'
    'notify:build_complete'
  ]
}
