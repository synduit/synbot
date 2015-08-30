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
#   HUBOT_JIRA_TRANSITION_IN_PROGRESS
#   HUBOT_JIRA_TRANSITION_DONE
#
# Commands:
#   hubot jira my username is <username>
#   hubot jira what is my username
#   hubot jira set board <board>
#   hubot jira get board
#   hubot jira set sprint <sprint>
#   hubot jira get sprint
#   hubot jira my issues
#   hubot jira working <issue>
#   hubot jira done <issue>
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  # Command: hubot jira my username is <username>
  robot.respond /jira\s+my\s+(?:user\s*name|login)+\s+is\s+(\w+)/i, (msg) ->
    user = msg.message.user
    jiraUsername = msg.match[1]
    user.jiraUsername = jiraUsername
    msg.send "OK #{user.name}, your JIRA username is #{jiraUsername}."

  # Command: hubot jira what is my username
  robot.respond /jira\s+what\s+is\s+my\s+(?:user\s*name|login)+\s*\?*/i, (msg) ->
    jiraUsername = msg.message.user.jiraUsername or false
    if jiraUsername
      msg.send "#{res.message.user.name}, you are #{jiraUsername} on JIRA."
    else
      msg.send "I don't know your JIRA username."

  # Command: hubot jira set board <board>
  robot.respond /jira\s+set\s+board\s+(\d+)/i, (msg) ->
    board = msg.match[1]
    roomName = msg.envelope.room
    rooms = robot.brain.get('rooms') or {}
    rooms[roomName].board = board
    robot.brain.set('rooms', rooms)
    msg.send "OK, scrum board for room #{roomName} set to #{board}."

  # Command: hubot jira get board
  robot.respond /jira\s+get\s+board/i, (msg) ->
    roomName = msg.envelope.room
    rooms = robot.brain.get('rooms') or {}
    board = rooms[roomName].board if rooms[roomName]?
    if board
      msg.send "Scrum board for this room is #{board}."
    else
      msg.send "No board has been set for this room."

  # Command: hubot jira set sprint <sprint>
  robot.respond /jira\s+set\s+sprint\s+(\d+)/i, (msg) ->
    sprint = msg.match[1]
    roomName = msg.envelope.room
    rooms = robot.brain.get('rooms') or {}
    rooms[roomName].sprint = sprint
    robot.brain.set('rooms', rooms)
    msg.send "OK, sprint for room #{roomName} set to #{sprint}."

  # Command: hubot jira get sprint
  robot.respond /jira\s+get\s+sprint/i, (msg) ->
    roomName = msg.envelope.room
    rooms = robot.brain.get('rooms') or {}
    sprint = rooms[roomName].sprint if rooms[roomName]?
    if sprint
      msg.send "Sprint for this room is #{sprint}."
    else
      msg.send "No sprint has been set for this room."

  # Command: hubot jira my issues
  robot.respond /jira\s+my\s+issues/i, (msg) ->
    getMyIssues msg, (issues) ->
      msg.send formatIssues issues

  # Command: hubot jira working <issue>
  robot.respond /jira\s+working\s+([a-zA-Z\-0-9]+)/i, (msg) ->
    issue = msg.match[1]
    transition = process.env.HUBOT_JIRA_TRANSITION_IN_PROGRESS
    unless transition
      msg.send "HUBOT_JIRA_TRANSITION_IN_PROGRESS environment variable must be set."
      return
    setIssueTransition msg, issue, transition, (code) ->
      if code == 204
        msg.send "OK, setting #{issue} to In Progress."
      else
        msg.send "Error setting #{issue} to In Progress."

  # Command: hubot jira done <issue>
  robot.respond /jira\s+done\s+([a-zA-Z\-0-9]+)/i, (msg) ->
    issue = msg.match[1]
    transition = process.env.HUBOT_JIRA_TRANSITION_DONE
    unless transition
      msg.send "HUBOT_JIRA_TRANSITION_IN_DONE environment variable must be set."
      return
    setIssueTransition msg, issue, transition, (code) ->
      if code == 204
        msg.send "OK, setting #{issue} to Done."
      else
        msg.send "Error setting #{issue} to Done."

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

# Get JIRA API URL
getJiraURL = (msg, resource) ->
  domain = process.env.HUBOT_JIRA_DOMAIN
  unless domain
    msg.send "HUBOT_JIRA_DOMAIN environment variable must be set to a valid <ORG>.atlassian.net domain."
    return
  apiURL = "https://" + domain + "/rest/api/2/" + resource
  return apiURL

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
      callback(err, JSON.parse(body))

# Get Collection over HTTP
getCollection = (msg, url, params, auth, key, result, callback) ->
  if (!params.startAt?)
    params.startAt = 0
  msg.http(url)
    .header('Authorization', auth)
    .query(params)
    .get() (err, res, body) ->
      if err
        callback(err, result)
      else
        json = JSON.parse(body)
        result.push json[key]...
        if json.startAt + json.maxResults < json.total
          params.startAt += json.maxResults
          getCollection(msg, url, params, auth, key, result, callback)
        else
          callback(err, result)

# Get active sprint
getActiveSprint = (msg, callback) ->
  auth = getAuth(msg)
  url = getAgileURL(msg, "board/5/sprint")
  params =
    state: "active"
  getResource msg, url, params, auth, (err, json) ->
    if err
      msg.send "Error getting Sprint from JIRA."
      return
    if json.values.length <= 0
      msg.send "There is no active sprint."
      return
    sprint = json.values[0].id
    callback(sprint)

# Get my issues
getMyIssues = (msg, callback) ->

  auth = getAuth(msg)

  roomName = msg.envelope.room
  rooms = robot.brain.get('rooms') or {}

  board = rooms[roomName].board if rooms[roomName]?
  unless board
    msg.send "Please set scrum board."
    return

  sprint = rooms[roomName].sprint if rooms[roomName]?
  unless sprint
    msg.send "Please set sprint."
    return

  jiraUsername = msg.message.user.jiraUsername ? msg.message.user.name

  url = getAgileURL(msg, "board/#{board}/sprint/#{sprint}/issue")
  params =
    fields: "id,key,summary,issuetype,status,parent"
    jql: "issuetype in subTaskIssueTypes() AND status in (\"In Progress\", \"To Do\") AND assignee in (#{jiraUsername})"

  key = 'issues'
  result = []
  getCollection msg, url, params, auth, key, result, (err, issues) ->
    if err
      msg.send "Error getting issues from JIRA."
      return
    if issues.length <= 0
      msg.send "There are no issues open for you in this sprint."
      return
    callback(issues)

# Format issues
formatIssues = (issues) ->
  result = for issue in issues
    formatIssue issue
  result.join("\n")

# Format single issue
formatIssue = (issue) ->
  issue.key + " " + issue.fields.parent.fields.summary + " :: " + issue.fields.summary + " (" + issue.fields.status.name + ")"

# Set Issue Transition
setIssueTransition = (msg, issue, transition, callback) ->
  auth = getAuth(msg)
  url = getJiraURL(msg, "issue/#{issue}/transitions")
  body =
    transition:
      id: transition
  msg.http(url)
    .header('Authorization', auth)
    .header('Content-Type', 'application/json')
    .post(JSON.stringify(body)) (err, res, body) ->
      callback(res.statusCode)

