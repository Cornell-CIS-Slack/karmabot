# Description:
#   Karmabot scripts
#
# Notes:
#   Scripting documentation for hubot can be found here:
#   https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
  botname = process.env.HUBOT_SLACK_BOTNAME
  owner = process.env.HUBOT_SLACK_OWNERNAME

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

  robot.respond ///(leader|shame)board\s*([0-9]+|all)?///i, (msg) ->
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

    if msg.match[1] == "shame"
      tuples = (item for item in tuples when item[1] < 0)
      tuples.reverse()
    requested_count = msg.match[2]
    leaderboard_maxlen = if not requested_count? then 10\
      else if requested_count == "all" then tuples.length\
      else +requested_count
    str = ''
    add_spaces = (m) -> m + "\u200A"
    leader_message = if msg.match[1] == "shame"
      " (All shame the supreme loser!)"
    else
      " (All hail supreme leader!)"
    for i in [0...Math.min(leaderboard_maxlen, tuples.length)]
      username = tuples[i][0]
      points = tuples[i][1]
      point_label = if points == 1 then "point" else "points"
      leader = if i == 0 then leader_message else ""
      newline = if i < Math.min(leaderboard_maxlen, tuples.length) - 1 then '\n' else ''
      formatted_name = username.replace(/\S/g, add_spaces).trim()
      str += "##{i+1}\t[#{points} " + point_label + "] #{formatted_name}" + leader + newline
    msg.send(str)

  robot.respond ///help///i, (msg) -> 
        add_spaces = (m) -> m + "\u200A"
        formatted_owner = owner.replace(/\S/g, add_spaces).trim()
        help_msg  = "Usage:\n"
        help_msg += "\n"
        help_msg += "\tupbot help -- show this message\n"
        help_msg += "\t@<name>++ -- upvote <name>\n"
        help_msg += "\t@<name>-- -- downvote name\n"
        help_msg += "\tupbot leaderboard [n] -- list top n names; n defaults to 10\n"
        help_msg += "\tupbot shameboard [n] -- list bottom n names; n defaults to 10\n"
        help_msg += "\tupbot karma of @<name> -- list @<name>'s karma\n"
        help_msg += "\n"
        help_msg += "My code can be found at https://github.com/tmagrino/karmabot, please feel free to submit pull requests!\n"
        help_msg += "If you have any other questions, please ask my owner, @" + formatted_owner + "!"
        msg.send(help_msg)

  robot.respond ///karma\s+of\s+@([a-z0-9_\-\.]+)///i, (msg) ->
        user = msg.match[1].replace(/\-+$/g, '')
        count = robot.brain.get(user) or 0
        msg.send "@#{user} has #{count} karma!"
