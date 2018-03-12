# Description:
#   Manage Tech debt and performance time activity via Hubot
#
# Dependencies:
#   None
#
# Commands:
#   hubot i worked on performance for 10 hours
#   hubot i worked on techdebt for 10.5 hours
#   hubot report
#   hubot clear timetrack for all/username
#
# Author:
#   Santhosh GL
#
module.exports = (robot) ->
  # Command: i worked on performance for 10 hours.
  robot.respond /i\s+worked\s+on\s+([\w]+)\s+for\s+([\d\.]+)\s+([\w]+)/i, (msg) ->

    username = msg.message.user.name.toLowerCase()
    taskType = msg.match[1].toLowerCase()
    time = parseFloat(msg.match[2])
    period = msg.match[3].toLowerCase()
    timetrack = robot.brain.get('timetrack',timetrack) or []

    if period == 'hours' || period == 'hour' || period == 'hr'
      time = time * 60

    #if username is not set create one.
    if !timetrack[username]
      timetrack[username] = []

    #if username of tasktype is not then set to 0.
    if !timetrack[username][taskType]
      timetrack[username][taskType] = 0

    #if username have already have added time for a task then update them.
    if timetrack[username][taskType] == 0
      timetrack[username][taskType] = time
    else
      timetrack[username][taskType] += time

    robot.brain.set('timetrack', timetrack)

    msg.send "Thanks for contributing to  #{taskType} for #{time} minutes."


  robot.respond /report/i, (msg) ->
    # Command: report
    timetrack = robot.brain.get('timetrack',timetrack)
    totalHours = []
    for user,task of timetrack
      for  type of task
        if totalHours[type] ?
          totalHours[type] += task[type]
        else
          totalHours[type] = task[type]

    for type,minutes of totalHours
      msg.send "Total number of minutes worked on #{type} for #{minutes} minutes."

  robot.respond /clear\s+timetrack\s+for\s+([\w]+)/i, (msg) ->
  # Command: clear timetrack for <username>
    username = msg.match[1].toLowerCase()
    timetrack = robot.brain.get('timetrack',timetrack)
    if username == 'all'
      timetrack = ''
    else
      timetrack[username] = ''
    robot.brain.set('timetrack', timetrack)

    msg.send "The records have been cleared for #{username}"

