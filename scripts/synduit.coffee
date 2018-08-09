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
#   hubot who is <query>
#   hubot cancel <query>
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  # Command: hubot who is <query>
  robot.respond /who\s*is\s+([\w\W]+)/i, (msg) ->
    query = msg.match[1]
    getUser msg, query, (err, res) ->
      if err
        msg.send "Error getting info"
        console.log "Error getting info from Synduit: " + res
      else
        msg.send res

  # Command: hubot cancel <query>
  robot.respond /cancel\s+([\w\W]+)/i, (msg) ->
    query = msg.match[1]
    cancelUser msg, query, (err, res) ->
      if err
        msg.send "Error canceling user"
        console.log "Error canceling user from Synduit: " + res.statusCode
      else
        if res.statusCode == 204
          msg.send query + " is canceling"
        else
          msg.send "Error canceling user from Synduit: " + res.statusCode

getUser = (msg, query, callback) ->
  url = process.env.HUBOT_SYNDUIT_URL + "/v1/accounts/info?query=" + query
  msg.http(url)
    .header('Authorization', process.env.HUBOT_SYNDUIT_TOKEN)
    .get() (err, res, body) ->
      if err
        callback(err, res)
      else
        data = JSON.parse(body)
        result = "Subdomain: " + data.subdomain + "\n" +
          "Name: " + data.fname + " " + data.lname + "\n" +
          "Email: " + data.mail + "\n" +
          "Referral URL: " + data.referral_url
        callback(err, result)

cancelUser = (msg, query, callback) ->
  url = process.env.HUBOT_SYNDUIT_URL + "/v1/accounts/cancel?query=" + query
  msg.http(url)
    .header('Authorization', process.env.HUBOT_SYNDUIT_TOKEN)
    .header('Content-Type', 'application/json')
    .post("") (err, res, body) ->
      callback(err, res)
