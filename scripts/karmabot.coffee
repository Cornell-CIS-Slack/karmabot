# Description:
#   Karmabot scripts
#
# Notes:
#   Scripting documentation for hubot can be found here:
#   https://github.com/github/hubot/blob/master/docs/scripting.md

module.exports = (robot) ->
  botname = process.env.HUBOT_SLACK_BOTNAME
  owner = process.env.HUBOT_SLACK_OWNERNAME
  token = process.env.HUBOT_SLACK_TOKEN

  #upvote_reacts = ["+1", "thumbsup", "thumbsup_all", "beer", "parrot", "beers"]
  upvote_reacts = ["++", "upvote", "parrot", "beer", "beers"]
  #downvote_reacts = ["-1", "thumbsdown", "middle_finger"]
  downvote_reacts = ["--", "downvote", "middle_finger"]
  nonnotifying = (name) -> name.replace(/\S/g, (m) -> m + "\u200A").trim()

  # User being voted on, message that caused this vote, list of additional stuff to add to the end of the message.
  handle_upvote = (user, ts, msg, optionals...) ->
    notification = ""
    if msg.message.user.name == user
      notification += "@#{user}, you can't add to your own karma!"
    else
      count = (robot.brain.get(user) or 0) + 1
      robot.brain.set user, count
      notification += "@#{nonnotifying(user)}++ [woot! now at #{count}]"
    notification += optionals.map((x) -> " " + x)
    msg.send {text: notification, thread_ts: ts}

  # User being voted on, message that caused this vote
  handle_downvote = (user, ts, msg, optionals...) ->
    notification = ""
    if msg.message.user.name == user
      notification += "@#{user}, you are a silly goose and downvoted yourself!\n"
    count = (robot.brain.get(user) or 0) - 1
    robot.brain.set user, count
    notification += "@#{nonnotifying(user)}-- [ouch! now at #{count}]"
    notification += optionals.map((x) -> " " + x)
    msg.send {text: notification, thread_ts: ts}

  robot.react (res) ->
    rea = res.message
    # Handle the way skin tone modifiers work in the emojis
    reaction = rea.reaction.split(":")[0]
    voter = nonnotifying(res.message.user.name)
    # Add karma if someone reacts positive or removes a negative reaction
    # Remove karma if someone reacts negative or removes a positive reaction
    if ((reaction in upvote_reacts and rea.type == "added") or
        (reaction in downvote_reacts and rea.type == "removed"))
      handle_upvote(rea.item_user.name, rea.item.ts, res, "(:#{rea.reaction}: #{rea.type} by #{voter})")
    if ((reaction in downvote_reacts and rea.type == "added") or
        (reaction in upvote_reacts and rea.type == "removed"))
      handle_downvote(rea.item_user.name, rea.item.ts, res, "(:#{rea.reaction}: #{rea.type} by #{voter})")

  robot.hear ///@([a-z0-9_\-\.]+)\+{2,}///i, (msg) ->
    user = msg.match[1].replace(/\-+$/g, '')
    handle_upvote(user, msg.message.thread_ts, msg)

  robot.hear ///kick\s+jed///i, (msg) ->
    user = "jed"
    msg.send "/remove @#{user}"

  robot.hear ///@([a-z0-9_\-\.]+)\-{2,}///i, (msg) ->
    user = msg.match[1].replace(/\-+$/g, '')
    handle_downvote(user, msg.message.thread_ts, msg)

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
      formatted_name = nonnotifying(username)
      str += "##{i+1}\t[#{points} #{point_label}] #{formatted_name}" + leader + newline
    msg.send(str)

  robot.respond ///help///i, (msg) ->
        formatted_owner = nonnotifying(owner)
        help_msg  = "Usage:\n"
        help_msg += "\n"
        help_msg += "\t#{botname} help -- show this message\n"
        help_msg += "\t@<name>++ -- upvote <name>\n"
        help_msg += "\t@<name>-- -- downvote name\n"
        help_msg += "\t#{botname} leaderboard [n] -- list top n names; n defaults to 10\n"
        help_msg += "\t#{botname} shameboard [n] -- list bottom n names; n defaults to 10\n"
        help_msg += "\t#{botname} karma of @<name> -- list @<name>'s karma\n"
        help_msg += "\n"
        help_msg += "My code can be found at https://github.com/Cornell-CIS-Slack/upbot, please feel free to submit pull requests!\n"
        help_msg += "If you have any other questions, please ask my owner, @#{formatted_owner}!"
        msg.send(help_msg)

  robot.respond ///karma\s+of\s+@([a-z0-9_\-\.]+)///i, (msg) ->
        user = msg.match[1].replace(/\-+$/g, '')
        count = robot.brain.get(user) or 0
        msg.send "@#{user} has #{count} karma!"

  # Don't include the # for the channel name.
  welcome_channel = "general"
  welcome_message = """
*On behalf of the CS PhD students, welcome to Cornell CIS Slack!*

I'm @#{botname}, a bot managed by @#{owner} for tracking meaningless internet karma points in the Cornell CIS Slack.

Here are a few friendly pointers for new users that you might want to know:
- We have many different channels for activities ranging from ithaca lunch to board game night. *Type `/open` or click the Channels heading on the sidebar to see a full channel list.* In particular, you may be interested in #bulletin_board for widespread departmental announcements, #advice for general advice like help choosing classes or picking an advisor, or #cute_animals for when you want to see and share pictures of cute animals!
- Be sure to *edit your notification settings* so you're not overwhelmed. To do this, type `/prefs` to change global notification settings, or go to a specific channel and click the :bell: icon.
- If you want to learn more about @{botname} (that's me!), use the message `#{botname} help` for a summary of what I can do.

Enjoy, and let the karma flow!
"""

  # Allow for a welcome message to be sent to new users in the slack based on
  # the above settings for the channel and message.
  robot.enter (res) ->
        msg = res.message
        username = res.message.user.name
        if msg.room == welcome_channel
          console.log("#{username} welcomed.")
          robot.send { room: username, channel: username }, welcome_message
