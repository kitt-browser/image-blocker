TRANSFORMS = ['coffeeify', 'cssify', 'jadeify']

module.exports = (grunt) ->
  dev:
    files: [
      {src: '<%= srcDir %>/js/block.coffee', dest: "<%= buildDir %>/js/block.js"}
      {src: '<%= srcDir %>/js/content.coffee', dest: "<%= buildDir %>/js/content.js"}
    ]
    options:
      watch: true
      transform: TRANSFORMS
      external: [
        'jquery'
        '_'
        'URI'
      ]


  dist:
    files: "<%= browserify.dev.files %>",
    options:
      transform: TRANSFORMS.concat([])
      external: "<%= browserify.dev.options.external %>"

  test:
    src: ['<%= srcDir %>/js/*.spec.coffee'],
    dest: "<%= buildDir %>/test/browserified_tests.js",
    options:
      watch: true
      debug: true
      transform: ['coffeeify', 'cssify']
      external: "<%= browserify.dev.options.external %>"

   libs:
    src: []
    dest: "<%= buildDir %>/js/libs.js"
    options:
      require: [
        'jquery'
        'lodash'
        'URIjs'
      ]
