_ = require('lodash')
URI = require('URIjs')

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
allowedURLs = []


sendMessage = (msg, callback) ->
  chrome.tabs.query {active: true, currentWindow: true}, (tabs) ->
    chrome.tabs.sendMessage tabs[0].id, msg, (response) ->
      console.log(response)
      callback?(response)


chrome.webRequest.onBeforeRequest.addListener (details) ->
  console.log 'on before request'
  domain = details.url.split('?')[0]
  # Is the domain whitelisted?
  allowed = _.find allowedURLs, ({url}) -> domain.match(new RegExp(".*#{url}$"))
  shouldBlock = Boolean(domain.match(_imgExtensionsRegexp)) && not allowed
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
  console.log 'force load image', arguments
  sendMessage {command: 'getImageURL', src: info.linkUrl}, (url) ->
    console.log('allowing url', url)
    return unless url?
    domain = url.split('?')[0]
    # Whitelist the URL domain before reloading (otherwise it would just
    # get blocked again, duh).
    allowedURLs.push({url: encodeURI(domain), tabId: tab.id})
    console.log('whitelisting', url, tab.id)
    sendMessage {command: 'reloadImage', src: url}


chrome.runtime.onMessage.addListener (request) ->
  console.log 'received message', request
  switch (request.command)
    when 'clean'
      allowedURLs = []
      #_.filter allowedURLs, ({tabId}) -> tabId != sender.tab.id
