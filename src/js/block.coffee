$ = require('jquery')
_ = require('lodash')
URI = require('URIjs')

$.support.cors = true

# We don't have `accept` header yet so as a temporary workaround
# we're blocking by extension.
_imgExtensionsRegexp = new RegExp('.+(' + ([
  'jp(e)?g'
  'png'
  'gif'
  'tiff'
].join('|')) + ')$')


# Whitelisted domains.
# `[{url: <string>, tabId: <id>}]`
g_allowedURLs = []

g_data = {
  totalBlocked: 0
  totalDownloaded: 0
}


sendMessage = (msg, callback) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, msg, (response) ->
      console.log(response)
      callback?(response)


getHeadersForUrl = (url, callback) ->
  xhr = $.ajax(type: "HEAD", async: true, url: url)
  .done (data, status) ->
    callback?(null, xhr.getAllResponseHeaders())
  .fail (err) ->
    callback?(err)


###
chrome.webRequest.onHeadersReceived.addListener (details) ->
  return unless details['responseHeaders']?['Content-Length']?
  console.log 'type', typeof(details['responseHeaders']['Content-Length'])
  try
    size = parseInt(details['responseHeaders']['Content-Length'])
  catch e
    console.log 'exception'
  g_data.totalDownloaded += (size or 0)
###

escapeRegExp = (str) ->
  return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")


chrome.webRequest.onBeforeRequest.addListener (details) ->
  domain = details.url.split('?')[0]

  # Is the domain whitelisted?
  allowed = _.find g_allowedURLs, ({url}) ->
    domain.match(new RegExp(".*#{escapeRegExp(url)}$"))
  shouldBlock = Boolean(domain.match(_imgExtensionsRegexp)) &&
    not allowed && details.method == 'GET'

  if shouldBlock
    # Determine the size of the blocked image (to show stats to the user).
    getHeadersForUrl details.url, (err, headers) ->
      if err then return
      # Get Content Length header value as a number.
      matches = headers.match /.*Content-Length:.*([0-9])+.*/g, '$1'
      return unless matches?.length > 0
      size = Number(matches[0].split(':')[1])
      g_data.totalBlocked += size

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


chrome.contextMenus.onClicked.addListener (info, tab) ->
  return unless (info.menuItemId == menu)
  sendMessage {command: 'getImageURL', src: info.linkUrl}, (url) ->
    return unless url?
    domain = url.split('?')[0]
    # Whitelist the URL domain before reloading (otherwise it would just
    # get blocked again, duh).
    g_allowedURLs.push({url: encodeURI(domain), tabId: tab.id})
    sendMessage {command: 'reloadImage', src: url}


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log 'received message', request
  switch (request.command)
    when 'clean'
      g_allowedURLs = []
      #_.filter allowedURLs, ({tabId}) -> tabId != sender.tab.id
      break
    when 'data:info'
      sendResponse {
        blocked: g_data.totalBlocked
        received: g_data.totalDownloaded
      }
      break
