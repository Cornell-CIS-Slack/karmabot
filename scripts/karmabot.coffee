# Description:
#   Karmabot scripts
#
# Notes:
#   Scripting documentation for hubot can be found here:
#   https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
  botname = process.env.HUBOT_SLACK_BOTNAME

  robot.hear ///@([a-z0-9_\-\.]+)\+{2,}///i, (msg) ->
    user = msg.match[1].replace(/\-+$/g, '')
    if msg.message.user.name == user
      response_msg = "@" + user
      response_msg += ", you can't add to your own karma!"
      msg.send response_msg
    else
      count = (robot.brain.get(user) or 0) + 1
      robot.brain.set user, count
      msg.send "@#{user}++ [woot! now at #{count}]"

  robot.hear ///@([a-z0-9_\-\.]+)\-{2,}///i, (msg) ->
    user = msg.match[1].replace(/\-+$/g, '')
    if msg.message.user.name == user
      response_msg = "@" + user
      response_msg += ", you are a silly goose and downvoted yourself!"
      msg.send response_msg
    count = (robot.brain.get(user) or 0) - 1
    robot.brain.set user, count
    msg.send "@#{user}-- [ouch! now at #{count}]"

  robot.hear ///@#{botname}\s*:?\s+leaderboard\s+(\d+)?///i, (msg) ->
    users = robot.brain.data._private
    tuples = []
    for username, score of users
      tuples.push([username, score])

    if tuples.length == 0
      msg.send "The lack of karma is too damn high!"
      return

    tuples.sort (a, b) ->
      if a[1] > b[1]
        return -1
      else if a[1] < b[1]
        return 1
      else
        return 0

    leaderboard_maxlen = 10

    if res.match[0].test///\d+///
        leaderboard_maxlen = parseInt(res.match[0].match///\d+///[0])
    str = ''
    add_spaces = (m) -> m + "\u200A"
    for i in [0...Math.min(leaderboard_maxlen, tuples.length)]
      username = tuples[i][0]
      points = tuples[i][1]
      point_label = if points == 1 then "point" else "points"
      leader = if i == 0 then " (All hail supreme leader!)" else ""
      newline = if i < Math.min(leaderboard_maxlen, tuples.length) - 1 then '\n' else ''
      formatted_name = username.replace(/\S/g, add_spaces).trim()
      str += "##{i+1}\t[#{points} " + point_label + "] #{formatted_name}" + leader + newline
    msg.send(str)

  robot.hear ///@#{botname}\s*:?\s+loserboard\s*(\d+)?///i, (msg) -> #yay copy-and-paste design pattern!
    users = robot.brain.data._private
    tuples = []
    for username, score of users
      tuples.push([username, score])

    if tuples.length == 0
      msg.send "The lack of karma is too damn high!"
      return

    tuples.sort (a, b) ->
      if a[1] > b[1]
        return 1
      else if a[1] < b[1]
        return -1
      else
        return 0

    leaderboard_maxlen = 10
    if res.match[0].test///\d+///
        leaderboard_maxlen = parseInt(res.match[0].match///\d+///[0])
    str = ''
    add_spaces = (m) -> m + "\u200A"
    for i in [0...Math.min(leaderboard_maxlen, tuples.length)]
      username = tuples[i][0]
      points = tuples[i][1]
      point_label = if points == 1 then "point" else "points"
      leader = if i == 0 then " (All hail supreme leader!)" else ""
      newline = if i < Math.min(leaderboard_maxlen, tuples.length) - 1 then '\n' else ''
      formatted_name = username.replace(/\S/g, add_spaces).trim()
      str += "##{i+1}\t[#{points} " + point_label + "] #{formatted_name}" + leader + newline
    msg.send(str)
