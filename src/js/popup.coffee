$ = require('jquery')


sendMessage = (msg, callback) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, msg, (response) ->
      console.log(response)
      callback?(response)

getBytesWithUnit = (bytes) ->
  if isNaN(bytes) then return
  units = [
    " bytes", " KB", " MB", " GB", " TB", " PB", " EB", " ZB", " YB"
  ]
  amountOf2s = Math.floor(Math.log(+bytes) / Math.log(2))
  if amountOf2s < 1
    amountOf2s = 0
  i = Math.floor(amountOf2s / 10)
  bytes = +bytes / Math.pow(2, 10 * i)
  
  # Rounds to 3 decimals places.
  if bytes.toString().length > bytes.toFixed(3).toString().length
    bytes = bytes.toFixed(3)
  bytes + units[i]


$ ->
  chrome.runtime.sendMessage {command:'settings:get'}, (settings) ->
    console.log 'setting cellular checkbox', settings
    $('.reachability input').prop 'checked',
      (settings.reachability.length == 1 &&
      settings.reachability.indexOf('Cellular') >= 0)

  updateStats = ->
    chrome.runtime.sendMessage {command: 'data:info'}, (obj) ->
      $('.totalBlocked .data').html(getBytesWithUnit(obj.blocked))
      #$('.totalReceived .data').html((obj.received/1024).toFixed(2) + ' KB')

  $('button.reset').on 'click', ->
    chrome.runtime.sendMessage {command:'reset'}, ->
      updateStats()

  $('button.bkg-load').on 'click', ->
    sendMessage {command: 'reload:background'}
    window.close()

  $('button.all-images-load').on 'click', ->
    sendMessage {command: 'reload:all'}
    window.close()

  $('.reachability input').on 'click', ->
    console.log 'clicked reachability', $(this).is(':checked')
    onlyBlockCellular = $(this).is(':checked')
    chrome.runtime.sendMessage {
      command: 'reachability:set'
      block: {
        cellular: true
        wifi: (not onlyBlockCellular)
      }
    }, ->

  updateStats()
