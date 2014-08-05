$ = require('jquery')
URI = require('URIjs')

$.support.cors = true


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

  imgSrc = $img.attr('src')
  d = new Date()

  # We add some query salt (current timestamp) to the URL to force reload.
  if ~imgSrc.indexOf('?')
    $img.attr('src', "#{imgSrc}&#{d.getTime()}")
  else
    $img.attr('src', "#{imgSrc}?#{d.getTime()}")

  console.log 'updated image url', $img.attr('src')

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  console.log('message received:', request.command, request)

  switch (request.command)
    when 'getImageURL'
      url = getImageURL(request.src)
      sendResponse(url)
      break

    when 'reloadImage'
      reloadImage(request.src)
      sendResponse(null)
      break


$ ->
  console.log 'window ON LOAD'
  chrome.runtime.sendMessage {command: 'clean'}, ->
    console.log 'cleaning done'
