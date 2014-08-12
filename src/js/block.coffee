$ = require('jquery')
_ = require('lodash')
URI = require('URIjs')
common = require('./common.coffee')

g_settings = require('./default.coffee')

$.support.cors = true


# We don't have `accept` header yet so as a temporary workaround
# we're blocking by extension.
_imgExtensionsRegexp = new RegExp('.+(' + ([
  'jp(e)?g'
  'png'
  'gif'
  'tiff'
].join('|')) + ')$', 'i')


# Whitelisted domains.
# `[{url: <string>, tabId: <id>}]`
g_allowedURLs = []

# Stats
g_data = {
  totalBlocked: 0
  totalDownloaded: 0
}


sendMessage = (msg, callback) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, msg, (response) ->
      console.log('response', response)
      callback?(response)


# Send a HEAD request (used to get Content-Length).
getHeadersForUrl = (url, callback) ->
  xhr = $.ajax(type: "HEAD", async: true, url: url)
  .done (data, status) ->
    callback?(null, xhr.getAllResponseHeaders())
  .fail (err) ->
    callback?(err)


chrome.webRequest.onHeadersReceived.addListener (details) ->
  size = parseInt(details['responseHeaders']?['Content-Length'])
  console.log 'size', details['responseHeaders']?['Content-Length'], size
  g_data.totalDownloaded += (size or 0)
  return

escapeRegExp = (str) ->
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")


chrome.webRequest.onBeforeRequest.addListener (details) ->
  # Check if we should block on this type of connection.
  if g_settings.reachability.indexOf(details.reachability) < 0
    return

  domain = encodeURI(details.url.split('?')[0])
  # Is the domain whitelisted?
  allowed = _.find g_allowedURLs, ({url}) ->
    domain.match(new RegExp(".*#{escapeRegExp(url)}$"))
  shouldBlock = Boolean(domain.match(_imgExtensionsRegexp)) &&
    not allowed && details.method == 'GET'

  console.log 'url', details, shouldBlock

  if shouldBlock
    # Determine the size of the blocked image (to show stats to the user).
    getHeadersForUrl details.url, (err, headers) ->
      if err then return
      # Get Content Length header value (as a number).
      matches = headers.match /.*Content-Length:.*([0-9])+.*/g, '$1'
      return unless matches?.length > 0
      size = Number(matches[0].split(':')[1])
      g_data.totalBlocked += size

  if shouldBlock then console.log('blocking url', details.url)

  return {cancel: shouldBlock }
, {
  urls: ["<all_urls>"]
}, ["blocking"]


menu = chrome.contextMenus.create({
  id: "imageBlockerMenu"
  title: 'Load image',
  contexts : ['link']
  enabled: true
})


whitelistUrl = (url) ->
  return unless url
  domain = encodeURI(url.split('?')[0])
  if g_allowedURLs.indexOf(domain) < 0
    g_allowedURLs.push({url: domain})
    console.log 'whitelisted URL', domain


chrome.contextMenus.onClicked.addListener (info, tab) ->
  console.log 'info', info
  return unless info.srcUrl
  whitelistUrl(info.srcUrl)
  sendMessage {command: 'reload:image', src: info.srcUrl}
  return


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'received message', request
  switch (request.command)
    when 'clean'
      g_allowedURLs = []

    when 'data:info'
      sendResponse {
        blocked: g_data.totalBlocked
        received: g_data.totalDownloaded
      }

    when 'url:whitelist'
      # TODO: We're getting junk "urls" such as "initial" or "none" here.
      # Filter what we're sending.
      whitelistUrl(request.url)
      sendResponse(null)

    when 'reachability:set'
      reachability = []
      if request.block.cellular then reachability.push 'Cellular'
      if request.block.wifi then reachability.push 'WiFi'

      common.getFromStorage 'settings', (settings = g_settings) ->
        settings.reachability = reachability
        common.saveToStorage 'settings', settings
        g_settings = settings

    when 'settings:get'
      common.getFromStorage 'settings', (settings = g_settings) ->
        sendResponse settings
      return true

