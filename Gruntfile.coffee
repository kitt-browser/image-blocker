module.exports = (grunt) ->

  path = require('path')
  require('time-grunt')(grunt)
  require('load-grunt-config')(grunt, {
    jitGrunt: true
    data:
      buildDir: "build"
      distDir : "dist"
      srcDir  : "src"
  })

  grunt.registerTask 'upload', ->
    grunt.fail.fatal("S3_FOLDER env var not specified") unless process.env.S3_FOLDER?
    grunt.task.run ['default', 's3:dist']
