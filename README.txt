##############################
# FOREVERBOT BY FOREVERNIGHT #
##############################

This bot is a (basic) replacement for TheCheatBot as made by ThePoopsmith for #nrg on gamesurge.

This bot accepts commands via the . operator, it currently only has 2 commands implemented.

.servers = lists the servers found in the servers.list file

.view <servername> = lists the users found within the specified server
	note, the servername must match the name within servers.list

This bot is invoked via the command line.

ruby foreverBot.rb <server> <port> <name> <initial channel>

it will autojoin the initial channel after the server finishes up the MOTD file, however it is not guarenteed to work. If it doesn't autojoin the channel, just invite the bot into the channel, it will autoaccept the invite.

If you have any questions about the bot and how it works you can find me on IRC. I'm on gamesurge in #nrg (among many others) as Hann. If IRC isn't your "thing" (why you're using an ircbot I don't know) you can email me at foreverNight@editmyconfigsbitch.net