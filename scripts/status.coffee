# Description:
#   Get status of Third party services
#
# Dependencies:
#   None
#
# Commands:
#   hubot status github
#
# Author:
#   Liptan Biswas
#
module.exports = (robot) ->
  # Command: hubot status github
  robot.respond /status\s+github/i, (msg) ->
    getGithubStatus msg, (err, res) ->
      if err
        msg.send "Error getting info from Github API"
        console.log "Error getting info from Github API: " + res
      else
        msg.send res

getGithubStatus = (msg, callback) ->
  url = "https://status.github.com/api/last-message.json"
  msg.http(url)
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      if err
        callback(err, res)
      else
        data = JSON.parse(body)
        message = ""
        if data.status is "good"
          message = "*GitHub is fully oprational.*"
        else if data.status is "minor"
          message = "*GitHub is running into minor issues.*\nHere's what they say: _#{data.body}_"
        else if data.status is "major"
          message = "*GitHub is running into major issues.*\nHere's what they say: _#{data.body}_"
        else
          message  =  "I don't know the status of GitHub. Visit https://status.github.com for more info."
        callback(err, message)
