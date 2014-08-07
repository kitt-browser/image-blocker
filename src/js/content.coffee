$ = require('jquery')
URI = require('URIjs')
_ = require('lodash')


getRelativeUrl = (url) ->
  uri = new URI(url)
  domainMatch = new RegExp("#{uri.scheme()}:\/\/[^\/]+(.+)")
  return url.replace domainMatch, '$1'


getImageURL = (url) ->
  # Make URL relative to root. Kitt makes all URLs absolute before passing them
  # to us. But jQuery needs a (semi-)exact string match so we have to search
  # for relative URLs too.
  relativeURL = getRelativeUrl(url)
  $img = $("*[src$='#{url}'], *[href$='#{url}'], " +
    "*[src$='#{relativeURL}'], *[href$='#{relativeURL}']")

  console.log 'searching for image...', $img.length

  return null unless $img.length

  # Oftentimes the image is wrapped in a <a> tag so we need to get it from
  # within.
  if ! $img.is('img') then $img = $img.children('img:first')
  return null unless $img.length

  return $img.attr('src')


reloadCSSBackgroundImages = ->
  console.log 'reloading CSS background images...'
  for sheet in document.styleSheets
    for rule  in (r for r in sheet.cssRules)
      do (rule) ->
        if rule?.style?['background-image']
          old = rule.style['background-image']
          chrome.runtime.sendMessage {
            command: 'url:whitelist'
            url: old.replace(/url\((.*)\)/, '$1')
          }, ->
          rule.style['background-image'] = ''
          setTimeout ->
            console.log 'reloading bkg image rule'
            rule.style['background-image'] = old
          , 100


reloadImage = (url) ->
  uri = new URI(url)
  relativeURL = getRelativeUrl(url)

  $img = $("img[src='#{url}'], img[src$='#{relativeURL}']")
  console.log $img.length
  return unless $img.length

  # Flash `src` => force reload.
  imgSrc = $img.attr('src')
  $img.attr('src', '')
  setTimeout ->
    console.log 'setting old img src', imgSrc
    $img.attr('src', imgSrc)
  , 100


chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log('message received:', request.command, request)

  switch (request.command)
    # We have to split image reloading into two async steps because
    # we need to whitelist the URL in the background script before we
    # reload.
    #
    # First we get the URL of the image to load.
    when 'getImageURL'
      url = getImageURL(request.src)
      sendResponse(url)
      break

    # Then we "flash" the `src` attribute to reload the image.
    when 'reload:image'
      reloadImage(request.src)
      sendResponse(null)
      break

    when 'reload:background'
      reloadCSSBackgroundImages()


$ ->
  # Ask the background script to remove the whitelisted URLs from the previous
  # page (saving memory).
  chrome.runtime.sendMessage {command: 'clean'}, ->
    console.log 'cleaning done'
