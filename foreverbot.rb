#!/usr/local/bin/ruby
=begin
	LICENSE:

	Copyright (c) 2013, Hann <foreverNight>
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


	This is a project to replace (some) functionality found in TheCheatBot as made by thePoopsmith in 2008 - 2011
	This bot may not be the best, but it's how I'm learning Ruby, so deal. Features will be added as needed/requested, not all requested features will be used

	~Hann <foreverNight@editmyconfigsbitch.net>
=end

require "socket"

#parses the serverfile and grabs the hostname and port associatd with the servername
def parse_server_infos(q3_server)
	File.open(".\\servers.list").each do |line|
	
	case line
	
		when /^#/
			#do nothing
		when /^\n/
			#do nothing
		else
			hostInfo = line.split(" ")
			if (hostInfo[0] == q3_server)
				return hostInfo[1], hostInfo[2]		#return the hostname and port of the server
			end
		end
	end
	return -1, -1
end

#query the given server from the file, and display the players on a q3a based server, currently biased towards urt 4.x, needs testing on q3a
def get_players(q3_server, irc_channel)
	infos = parse_server_infos(q3_server)
	sock = UDPSocket.new()

	if (infos[0] == -1 || infos[1] == -1)
		S.puts("PRIVMSG #{irc_channel} : Error obtaining server info")
	else
		sock.connect(infos[0], infos[1])
		sock.printf("\xFF\xFF\xFF\xFFgetstatus", 0)		#send getstatus string to server
		msg = sock.recv(1024);							#get the data
		sock.close()									#might as well clean up
		newLine = msg[20..msg.length - 1].split("\n")	#split the output into an array
		msg = nil										#clean up by destroying msg
		sock = nil
		playerLine = ""
		if (newLine.length == 1)
			playerLine << "There are no players on #{q3_server} :("
		else
			for i in 1..newLine.length - 1
				subPlayer = newLine[i].split(" ")
				playerLine << subPlayer[2]
				playerLine << ", "
			end
		end
		S.puts "PRIVMSG #{irc_channel} : \00312,8#{playerLine}"
	end
end

#parse the server file and output the contents
def get_servers(irc_channel)
	serverLine = ""
	File.open(".\\servers.list").each do |line|
		case line
	
		when /^#/
			#do nothing, # = comment character at beginning of line
		when /^\n/
			#do nothing, new line at the beginning means whitespace
		else
			split = line.split(" ")
			serverLine << split[0]
			serverLine << ", "
		end
	end

	serverLine = serverLine[0..serverLine.length - 3]  			#trim off the ending
	S.puts("PRIVMSG #{irc_channel} : \00312,8#{serverLine}")
end

#answer invites by joining the channel in question and putting a message
def do_invite(irc_channel)
	S.puts("JOIN #{irc_channel}")
	S.puts("PRIVMSG #{irc_channel} : I AM HERE, CLICK ME")
end

#handle server input
def handle_server_input(msg)	#handle any inputs from the server
		
	case msg.strip			#this isn't the best way of parsing our input, but we should see about fixing this later
		
	when /^PING :(.+)$/i
		puts "-->PING"
		S.puts "PONG #{$1}"
		puts "<--PONG"
	when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+?) :+[\001]PING (.+)[\001]$/i
		puts "-->PING #{$1}"  
		S.puts "NOTICE #{$1} :\001PING #{$4}\001"
		puts "<--PING #{$1}"
	when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s(.+?) :+[\001]VERSION[\001]$/i
		puts "-->VERSION #{$1}"
		S.puts "NOTICE #{$1} :\001VERSION NightIRC V0.001\001"
	when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s([#&][^\x07\x2C\s]{0,200})+\s:.view (.+?)$/i
			#/^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s([#&][^\x07\x2C\s]{0,200})+\s: <--- regex for Message within an IRC Channel according to RFC1459's Spec
		puts "-->.view #{$5} from #{$1}"
		get_players("#{$5}", "#{$4}")
	when /^:(.+?)!(.+?)@(.+?)\sPRIVMSG\s([#&][^\x07\x2C\s]{0,200})+\s:.servers$/i
		puts "-->Servers Request from #{$1}"
		get_servers("#{$4}")
	when /^:(.+?)!(.+?)@(.+?)\sINVITE\s(.+)\s([#&][^\x07\x2C\s]{0,200})$/i
		puts("-->Invite to #{$5} from #{$1}")
		do_invite("#{$5}")

		########need to find a way to condense these###########
	when /^.*END OF MESSAGE\(S\) OF THE DAY -.*/ #works on gsurge, allows for easy joining of a channel on startup
        puts "-->Ready to join<--"
        S.puts "JOIN \##{ARGV[3]}"
	when /^:(.+?)\s*\s(.+?)\s:End of MOTD command/ #works on editmyconfigsbitch
        puts "-->Ready to join<--"
        S.puts "JOIN \#{ARGV[3]}"
	else
		#puts (msg)				#uncomment this to see the output that isn't parsing, useful if a command isn't working
	end
end

#
# main entry point of the program
#

if (ARGV.length != 4)	#figure out a better way of doing this
	printf("USAGE: .\\foreverbot.rb <irc server> <irc port> <nick> <channel>\n")	#deomonstrate the proper usage of the bot to the user
else
	#take input from the command line arguments and set server port nick channel
	irc_server = ARGV[0]
	irc_port = ARGV[1]
	nick = ARGV[2]
	S = TCPSocket.open(irc_server, irc_port)
	printf("Addr: %s\n", S.addr.join(":"))			#print out the address and peer from the TCP Connection
	printf("Peer: %s\n", S.peeraddr.join(":"))
	S.puts("USER testing 0 * testing")				#set user and pass on connect
	S.puts("NICK #{nick}")
	until S.eof?  do
		msg = S.gets								#get msg from the Socket input
		handle_server_input(msg) 					#handle the input
	end
end