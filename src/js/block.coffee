_imgExtensionsRegexp = new RegExp('.+(' + ([
  'jp(e)?g'
  'png'
  'gif'
  'tiff'
].join('|')) + ')$')

chrome.webRequest.onBeforeRequest.addListener (details) ->
    domain = details.url.split('?')[0]
    console.log 'block domain? ', domain, Boolean(domain.match(imgExtensionsRegexp))
    return {
      cancel: Boolean domain.match imgExtensionsRegexp
    }
  , {
    urls: ["<all_urls>"]
  }, ["blocking"]

