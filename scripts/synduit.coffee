# Description:
#   Manage Synduit user accounts via Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SYNDUIT_URL
#   HUBOT_SYNDUIT_TOKEN
#
# Commands:
#   hubot who is <subdomain>
#   hubot cancel <subdomain>
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  # Command: hubot who is <subdomain>
  robot.respond /who\s*is\s+(\w+)/i, (msg) ->
    subdomain = msg.match[1]
    getUser msg, subdomain, (err, res) ->
      if err
        msg.send "Error getting info"
        console.log "Error getting info from Synduit: " + res
      else
        msg.send res

  # Command: hubot cancel <subdomain>
  robot.respond /cancel\s+(\w+)/i, (msg) ->
    subdomain = msg.match[1]
    cancelUser msg, subdomain, (err, res) ->
      if err
        msg.send "Error canceling user"
        console.log "Error canceling user from Synduit: " + res.statusCode
      else
        if res.statusCode == 204
          msg.send subdomain + " is canceling"
        else
          msg.send "Error canceling user from Synduit: " + res.statusCode

getUser = (msg, subdomain, callback) ->
  url = process.env.HUBOT_SYNDUIT_URL + "/v1/accounts/info?subdomain=" + subdomain
  msg.http(url)
    .header('Authorization', process.env.HUBOT_SYNDUIT_TOKEN)
    .get() (err, res, body) ->
      if err
        callback(err, res)
      else
        data = JSON.parse(body)
        result = "Subdomain: " + subdomain + "\n" +
          "Name: " + data.fname + " " + data.lname + "\n" +
          "Email: " + data.mail
        callback(err, result)

cancelUser = (msg, subdomain, callback) ->
  url = process.env.HUBOT_SYNDUIT_URL + "/v1/accounts/cancel?subdomain=" + subdomain
  msg.http(url)
    .header('Authorization', process.env.HUBOT_SYNDUIT_TOKEN)
    .post("") (err, res, body) ->
      callback(err, res)
