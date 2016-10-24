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
