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
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  robot.respond /jira\s+my\s+(?:user\s*name|login)+\s+is\s+(\w+)/i, (res) ->
    user = res.message.user
    jiraUsername = res.match[1]
    user.jiraUsername = jiraUsername
    res.send "OK #{user.name}, your JIRA username is " + jiraUsername


  robot.respond /jira\s+what\s+is\s+my\s+(?:user\s*name|login)+\s*\?*/i, (res) ->
    jiraUsername = res.message.user.jiraUsername or false
    if jiraUsername
      res.send "#{res.message.user.name}, you are #{jiraUsername} on JIRA"
    else
      res.send "I don't know your jira username"

