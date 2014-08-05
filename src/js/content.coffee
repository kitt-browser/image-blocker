$ = require('jquery')
URI = require('URIjs')


getImageURL = (url) ->
  # Make URL relative to root. Kitt makes all URLs absolute before passing them
  # to us. But jQuery needs a (semi-)exact string match so we have to search
  # for relative URLs too.
  uri = new URI(url)
  relativeURL = uri.relativeTo(uri.scheme() + '://' + uri.authority())
    .toString()
  $img = $("*[src$='#{url}'], *[href$='#{url}'], " +
    "*[src$='#{relativeURL}'], *[href$='#{relativeURL}']")

  console.log 'searching for image...', $img.length

  return null unless $img.length

  # Oftentimes the image is wrapped in a <a> tag so we need to get it from
  # within.
  if ! $img.is('img') then $img = $img.children('img:first')
  return null unless $img.length

  return $img.attr('src')


reloadImage = (url) ->
  console.log 'reloading url', url

  $img = $("img[src='#{url}']")
  return unless $img.length

  # Flash `src` => force reload.
  imgSrc = $img.attr('src')
  $img.attr('src', '')
  setTimeout (-> $img.attr('src', imgSrc)), 100


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
    when 'reloadImage'
      reloadImage(request.src)
      sendResponse(null)
      break


$ ->
  # Ask the background script to remove the whitelisted URLs from the previous
  # page (saving memory).
  chrome.runtime.sendMessage {command: 'clean'}, ->
    console.log 'cleaning done'
