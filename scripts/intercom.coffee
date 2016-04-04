# Description:
#   Use Intercom.io API
#
# Dependencies:
#   "intercom.io": "1.0.5"
#   "underscore": "1.7.0"
#   "q": "1.1.1"
#
# Configuration:
#   INTERCOM_API_KEY
#   INTERCOM_APP_ID
#
# Commands:
#   hubot intercom user <user id> - Show user info
#
# Author:
#   inakiabt

getSegments = (segments) ->
  promises = []
  i = segments.length - 1

  while i >= 0
    promises.push intercom.viewSegment(segment_id: segments[i])
    i--
  Q.all promises

generateSegments = (segments) ->
  noCache = []
  cache = []
  i = segments.length - 1

  while i >= 0
    segment = getCache("segment_" + segments[i].id)
    unless segment
      noCache.push segments[i].id
    else
      cache.push segment
    i--
  if noCache.length > 0
    return getSegments(noCache).then((newSegments) ->
      i = newSegments.length - 1

      while i >= 0
        storeCache "segment_" + newSegments[i].id, newSegments[i]
        i--
      newSegments.concat cache
    )
  Q.fcall ->
    cache

getMessage = (user) ->
  generateSegments((if user.segments then user.segments.segments else [])).then (segments) ->
    util.format "User: %s\nLink: https://app.intercom.io/apps/%s/users/%s\nSegments: %s\nTags: %s", user.name, options.appId, user.id, _.pluck(segments, "name").join(", "), _.pluck((if user.tags then user.tags.tags else []), "name").join(", ")

Intercom = require("intercom.io")
_ = require("underscore")._
Q = require("q")
util = require("util")
options =
  apiKey: process.env.INTERCOM_API_KEY
  appId: process.env.INTERCOM_API_ID

intercom = new Intercom(options)
CACHE = {intercom: {}}

getCache = (key) ->
  return null
  #return CACHE.intercom[key] or null

storeCache = (key, value) ->
  CACHE.intercom[key] = value
  return

module.exports = (robot) ->
  robot.brain.on 'loaded', =>
    CACHE.intercom = robot.brain.data.intercom or {}

  robot.hear /intercom user (.+)$/i, (message) ->
    showUserInfo message

showUserInfo = (message) ->
  user = message.match[1]
  # message.reply "Attempting to show info for user #{user}..."

  intercom.getUser(user_id: user).then((res) ->
    getMessage res
  ).then((msg) ->
    message.send msg
  ).fail (err) ->
    message.send util.format "Error getting user info: %s", err
    return
