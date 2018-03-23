# Description:
#   Manage Synpost action, resubscribe, via Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_SYNDUIT_COM
#   HUBOT_SYNPOST_URL
#   HUBOT_SYNPOST_USER
#   HUBOT_SYNPOST_PASSWORD
#
# Commands:
#   hubot resubscribe <subdomain> <email>
#
# Author:
#   Gauri Shankar Jha
#

module.exports = (robot) ->

  # Command: hubot resubscribe <subdomain> <email>
  robot.respond /resubscribe\s+([\S]+)\s+([\S]+)$/i, (msg) ->
    resubscribeAction msg, (err, res) ->
      if err
        msg.send "Error resubscribing user"
        console.log "Error resubscribing user: " + res + " " + res.statusCode
      else
        if res
          msg.send "Error resubscribing user: " + res
        else
          msg.send msg.match[2] + " is resubscribed"

resubscribeAction =  (msg, callback) ->
  url = process.env.HUBOT_SYNPOST_URL + "/admin/v1/subscribers/resubscribe"
  auth = "Basic " + new Buffer(process.env.HUBOT_SYNPOST_USER + ":" + process.env.HUBOT_SYNPOST_PASSWORD).toString('base64')
  # Trim subdomain
  subdomain = msg.match[1].replace /^\s+|\s+$/g, ""
  domain = subdomain + "." + process.env.HUBOT_SYNDUIT_COM
  # Trim email
  email = msg.match[2].replace /^\s+|\s+$/g, ""
  data = JSON.stringify({"type":"email", "email": email})
  msg.http(url)
    .header('Authorization', auth)
    .header('Content-Type', 'application/json')
    .header('X-SYNDUIT-DOMAIN', domain)
    .post(data) (err, res, body) ->
      if err
        callback(err, res)
      else
        if res.statusCode == 204
          errorMessage = ""
        else
          if res.statusCode == 401
            errorMessage = "Unauthorized access"
          else
            messageBody = JSON.parse(body)
            errorMessage = messageBody.error
        callback(err, errorMessage)
