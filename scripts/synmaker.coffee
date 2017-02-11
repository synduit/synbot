# Description:
#   Manage Synmaker via Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SYNMAKER_URL
#   HUBOT_SYNMAKER_USER
#   HUBOT_SYNMAKER_PASSWORD
#
# Commands:
#   hubot space
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  # Command: hubot space
  robot.respond /space\s*[\?]*$/i, (msg) ->
    getSpace msg, (err, res) ->
      if err
        msg.send "Error getting info"
        console.log "Error getting info from Synmaker: " + res
      else
        msg.send res

getSpace = (msg, callback) ->
  url = process.env.HUBOT_SYNMAKER_URL + "/v1/environments"
  auth = "Basic " + new Buffer(process.env.HUBOT_SYNMAKER_USER + ":" + process.env.HUBOT_SYNMAKER_PASSWORD).toString('base64')
  msg.http(url)
    .header('Authorization', auth)
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if err
        callback(err, res)
      else
        data = JSON.parse(body)
        result = ""
        totalSpace = 0
        for env in data.data
          space = env.capacity - env.app_count
          totalSpace += space
          result += env.name + " " + space + "\n"
        result += "Total " + totalSpace
        callback(err, result)
