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
#   hubot my jira username is <username>
#   hubot what is my jira username
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  robot.respond /my\s+jira\s+[user\s*name|login]+\s+is\s+(\w+)/i, (res) ->
    user = res.message.user
    jiraUsername = res.match[1]
    user.jiraUsername = jiraUsername
    res.send "OK #{user.name}, your jira username is " + jiraUsername


  robot.respond /what\s+is\s+my\s+jira\s+[user\s*name|login]\?*/i, (res) ->
    jiraUsername = res.message.user.jiraUsername or false
    if jiraUsername
      res.send "#{res.message.user.name}, you are #{jiraUsername} on JIRA"
    else
      res.send "I don't know your jira username"

