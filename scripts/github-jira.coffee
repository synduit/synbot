# Description:
#   Transition Jira subtask based on github webhook
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JIRA_DOMAIN
#   HUBOT_JIRA_TRANSITION_DONE
#   HUBOT_JIRA_USERNAME
#   HUBOT_JIRA_PASSWORD
#
# Webhook:
#   <hubot_url>:<hubot_port>/github
#
# Author:
#   Mani Soundararajan
#

module.exports = (robot) ->

  robot.router.post "/github", (req, res) ->
    data = req.body

    # TODO: Authenticate incoming webhook's HMAC digest

    if data.action == "labeled"
      title = data.pull_request.title
      matches = title.match(/^[A-Z0-9\-]+/g)
      ticket = matches[0]
      label = data.label.name
      user = data.sender.login
      robot.logger.info ticket + "," + label + "," + user
      if label == "ci:certified"
        setSubtaskDone ticket, "Testing", user
      else if label == "ci:reviewed"
        setSubtaskDone ticket, "Code Review", user
      else if label == "ci:accepted"
        setSubtaskDone ticket, "Acceptance", user

    if data.action == "opened"
      title = data.pull_request.title
      matches = title.match(/^[A-Z0-9\-]+/g)
      ticket = matches[0]
      user = data.sender.login
      robot.logger.info ticket + "," + data.action + "," + user
      setSubtaskDone ticket, "Development", user

    if data.action == "closed"
      if data.pull_request.merged
        title = data.pull_request.title
        matches = title.match(/^[A-Z0-9\-]+/g)
        ticket = matches[0]
        user = data.sender.login
        robot.logger.info ticket + "," + data.action + "," + user
        setSubtaskDone ticket, "Merge", user

    res.end "OK"

  # Command: hubot demo is done for <story>
  robot.respond /demo\s+([A-Z\' ']+)\s+([A-Z0-9\-]+)/i, (msg) ->
    done = msg.match[1].match('done|complete|over')
    ticket = msg.match[2]
    user = msg.message.user.name
    robot.logger.info ticket + ",Demo" + "," + user
    
    if done
      setSubtaskDone ticket, "Demo", user
      msg.send "OK, marking Demo for " + ticket + " as done."
    else
      msg.send "Something went wrong!!!"
# Get HTTP Basic Auth string
getAuth = () ->
  username = process.env.HUBOT_JIRA_USERNAME
  password = process.env.HUBOT_JIRA_PASSWORD
  auth = "Basic " + new Buffer(username + ":" + password).toString('base64')
  return auth

# Get JIRA API URL
getJiraURL = (resource) ->
  domain = process.env.HUBOT_JIRA_DOMAIN
  apiURL = "https://" + domain + "/rest/api/2/" + resource
  return apiURL

# Get Resource over HTTP
getResource = (url, params, auth, callback) ->
  robot.http(url)
    .header('Authorization', auth)
    .header('Accept', 'application/json')
    .query(params)
    .get() (err, res, body) ->
      callback(err, JSON.parse(body))

# Post data over HTTP
postData = (url, data, auth, callback) ->
  payload = JSON.stringify data
  robot.http(url)
    .header('Authorization', auth)
    .header('Content-Type', 'application/json')
    .header('Accept', 'application/json')
    .post(payload) (err, res, body) ->
      callback(err)

# Set subtask as done
setSubtaskDone = (ticket, match, user) ->
  auth = getAuth()
  url = getJiraURL('issue/' + ticket)
  getResource url, [], auth, (err, data) ->
    if err
      robot.logger.error "Error getting subtasks for " + ticket
    else
      subtasks = data.fields.subtasks
      for subtask in subtasks
        if subtask.fields.summary == match
          robot.logger.info "Setting " + subtask.key + " as done"
          doTransitionDone subtask.key

# Set issue as done(41)
doTransitionDone = (ticket) ->
  auth = getAuth()
  url = getJiraURL('issue/' + ticket + '/transitions')
  data = {transition: {id: process.env.HUBOT_JIRA_TRANSITION_DONE}}
  postData url, data, auth, (err) ->
    if err
      robot.logger.error "Error setting " + ticket + " to Done"
    else
      robot.logger.info ticket + " has been marked as Done"
