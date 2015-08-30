# Description:
#   Manage JIRA scrum activity via Hubot
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_DOMAIN
#   HUBOT_JIRA_USER
#   HUBOT_JIRA_PASSWORD
#
# Commands:
#   hubot jira my username is <username>
#   hubot jira what is my username
#   hubot jira set board <board>
#   hubot jira my issues
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  # Command: hubot jira my username is <username>
  robot.respond /jira\s+my\s+(?:user\s*name|login)+\s+is\s+(\w+)/i, (res) ->
    user = res.message.user
    jiraUsername = res.match[1]
    user.jiraUsername = jiraUsername
    res.send "OK #{user.name}, your JIRA username is " + jiraUsername

  # Command: hubot jira what is my username
  robot.respond /jira\s+what\s+is\s+my\s+(?:user\s*name|login)+\s*\?*/i, (res) ->
    jiraUsername = res.message.user.jiraUsername or false
    if jiraUsername
      res.send "#{res.message.user.name}, you are #{jiraUsername} on JIRA"
    else
      res.send "I don't know your jira username"

  # Command: hubot jira set board <board>
  robot.respond /jira\s+set\s+board\s+(\d+)/i, (msg) ->
    board = msg.match[1]
    roomName = msg.envelope.room
    rooms = robot.brain.get('rooms') or {}
    rooms[roomName].board = board
    robot.brain.set('rooms', rooms)
    msg.send "OK, scrum board for room #{roomName} set to #{board}"

  # Command: hubot jira my issues
  robot.respond /jira\s+my\s+issues/i, (msg) ->
    getActiveSprint msg, (sprint) ->
      msg.send "Current sprint is " + sprint

# Get HTTP Basic Auth string
getAuth = (msg) ->
  username = process.env.HUBOT_JIRA_USER
  password = process.env.HUBOT_JIRA_PASSWORD
  unless username
    msg.send "HUBOT_JIRA_USER environment variable must be set to a valid JIRA user's username."
    return
  unless password
    msg.send "HUBOT_JIRA_PASSWORD environment variable must be set to a valid JIRA user's password."
    return
  auth = "Basic " + new Buffer(username + ":" + password).toString('base64')
  return auth

#getJiraURL() = (msg, resource) ->
#  domain = process.env.HUBOT_JIRA_DOMAIN
#  unless domain
#    msg.send "HUBOT_JIRA_DOMAIN environment variable must be set to a valid <ORG>.atlassian.net domain."
#    return
#  apiURL = "https://" + domain + "/rest/api/2/" + resource
#  return apiURL
#

# Get JIRA Agile API URL
getAgileURL = (msg, resource) ->
  domain = process.env.HUBOT_JIRA_DOMAIN
  unless domain
    msg.send "HUBOT_JIRA_DOMAIN environment variable must be set to a valid <ORG>.atlassian.net domain."
    return
  apiURL = "https://" + domain + "/rest/agile/1.0/" + resource
  return apiURL

# Get Resource over HTTP
getResource = (msg, url, params, auth, callback) ->
  msg.http(url)
    .header('Authorization', auth)
    .query(params)
    .get() (err, res, body) ->
      callback( err, JSON.parse(body) )

# Get active sprint
getActiveSprint = (msg, callback) ->
  auth = getAuth(msg)
  url = getAgileURL(msg, "board/5/sprint")
  params =
    state: "active"
  getResource msg, url, params, auth, (err, json) ->
    if err
      msg.send "Error getting Sprint from JIRA"
      return
    if json.values.length <= 0
      msg.send "There is no active sprint."
      return
    sprint = json.values[0].id
    callback(sprint)

