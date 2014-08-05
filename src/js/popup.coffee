$ = require('jquery')

$ ->
  console.log 'popup loaded'
  chrome.runtime.sendMessage {command: 'data:info'}, (obj) ->
    $('.totalBlocked .data').html((obj.blocked/1024).toFixed(2) + ' KB')
