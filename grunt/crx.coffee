module.exports = {
  main:
    src: ["<%= buildDir %>/**"]
    filename: '<%= package.name %>' + '.crx'
    dest: "<%= distDir %>"
    baseURL: "http://localhost:8777/" # clueless default
    privateKey: 'key.pem'
}
