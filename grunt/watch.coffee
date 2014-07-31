module.exports = {
  manifest:
    files: [
      '<%= srcDir %>/manifest.json'
    ]
    tasks: ['copy:manifest', 'test']

  sources:
    files: [
      '<%= buildDir %>/**/*.coffee',
      '<%= buildDir %>/**/*.js'
    ]
    tasks: ['test']

  html:
    files: ['<%= srcDir %>/**/*.html']
    tasks: ['copy:html', 'test']

  css:
    files: ['<%= srcDir %>/**/*.css']
    tasks: ['copy:css', 'test']

  img:
    files: ['<%= srcDir %>/img/**/*.*']
    tasks: ['copy:img', 'test']
}
