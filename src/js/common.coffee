getFromStorage = (key, callback) ->
  chrome.storage.local.get key, (items) ->
    callback null, items[key]


saveToStorage = (key, val, callback) ->
  obj = {}
  obj[key] = val
  chrome.storage.local.set obj, ->
    callback?()

module.exports = {
  getFromStorage: getFromStorage,
  saveToStorage: saveToStorage,
}
