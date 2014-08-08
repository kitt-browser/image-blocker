$ = require('jquery')


sendMessage = (msg, callback) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, msg, (response) ->
      console.log(response)
      callback?(response)


$ ->
  chrome.runtime.sendMessage {command: 'data:info'}, (obj) ->
    $('.totalBlocked .data').html((obj.blocked/1024).toFixed(2) + ' KB')
    $('.totalReceived .data').html((obj.received/1024).toFixed(2) + ' KB')

  $('button.bkg-load').on 'click', ->
    sendMessage {command: 'reload:background'}
    window.close()

  $('button.all-images-load').on 'click', ->
    sendMessage {command: 'reload:all'}
    window.close()
