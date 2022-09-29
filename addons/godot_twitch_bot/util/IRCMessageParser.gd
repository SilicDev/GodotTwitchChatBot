extends Reference


static func parse_message(message: String):
	var parsedMessage := {  # Contains the component parts.
		"tags" : null,
		"source" : null,
		"command" : null,
		"parameters" : null,
	}
	
	# The start index. Increments as we parse the IRC message.
	var idx := 0
	
	# The raw components of the IRC message.
	var rawTagsComponent = null
	var rawSourceComponent = null
	var rawCommandComponent = null
	var rawParametersComponent = null
	
	# If the message includes tags, get the tags component of the IRC message.
	if message.substr(idx, 1) == '@': # The message includes tags.
		var endIdx = message.find(' ')
		rawTagsComponent = message.substr(1, endIdx - 1);
		idx = endIdx + 1 # Should now point to source colon (:).
	
	# Get the source component (nick and host) of the IRC message.
	# The idx should point to the source part; otherwise, it's a PING command.
	if message.substr(idx, 1) == ':':
		idx += 1
		var endIdx = message.find(' ', idx)
		rawSourceComponent = message.substr(idx, endIdx - 1)
		idx = endIdx + 1  # Should point to the command part of the message.
	
	# Get the command component of the IRC message.
	var endIdx = message.find(':', idx)  # Looking for the parameters part of the message.
	if endIdx == -1:                     # But not all messages include the parameters part.
		endIdx = message.length()                 
	rawCommandComponent = message.substr(idx, endIdx).trim_suffix(" ").trim_suffix("\r\n")

	# Get the parameters component of the IRC message.
	if endIdx != message.length():  # Check if the IRC message contains a parameters component.
		idx = endIdx + 1            # Should point to the parameters part of the message.
		rawParametersComponent = message.substr(idx)
	
	# Parse the command component of the IRC message.
	parsedMessage.command = parseCommand(rawCommandComponent)
	
	# Only parse the rest of the components if it's a command
	# we care about; we ignore some messages.
	
	if not parsedMessage.command:  # Is null if it's a message we don't care about.
		return null
	else:
		if rawTagsComponent:  # The IRC message contains tags.
			parsedMessage.tags = parseTags(rawTagsComponent)
		
		parsedMessage.source = parseSource(rawSourceComponent)
		
		parsedMessage.parameters = rawParametersComponent
		if rawParametersComponent and rawParametersComponent[0] == '!':  
			# The user entered a bot command in the chat window.            
			parsedMessage.command = parseParameters(rawParametersComponent, parsedMessage.command)
	
	return parsedMessage


# Parses the tags component of the IRC message.
static func parseTags(tags) -> Dictionary:
	# badge-info=;badges=broadcaster/1;color=#0000FF;...

	var tagsToIgnore = {  # List of tags to ignore.
		'client-nonce': null,
		'flags': null,
	}

	var dictParsedTags = {}  # Holds the parsed list of tags.
							 # The key is the tag's name (e.g., color).
	var parsedTags = tags.split(';');

	for tag in parsedTags:
		var parsedTag = tag.split('=')  # Tags are key/value pairs.
		var tagValue = null if parsedTag[1] == '' else parsedTag[1]

		match parsedTag[0]:  # Switch on tag name
			'badges','badge-info':
				# badges=staff/1,broadcaster/1,turbo/1;

				if tagValue :
					var dict = {}  # Holds the list of badge objects.
									# The key is the badge's name (e.g., subscriber).
					var badges = tagValue.split(',')
					for pair in badges:
						var badgeParts = pair.split('/')
						dict[badgeParts[0]] = badgeParts[1]
					dictParsedTags[parsedTag[0]] = dict
				else:
					dictParsedTags[parsedTag[0]] = null
			'emotes':
				# emotes=25:0-4,12-16/1902:6-10

				if tagValue:
					var dictEmotes = {}  # Holds a list of emote objects.
										 # The key is the emote's ID.
					var emotes = tagValue.split('/')
					for emote in emotes:
						var emoteParts = emote.split(':')

						var textPositions = []  # The list of position objects that identify
												# the location of the emote in the chat message.
						var positions = emoteParts[1].split(',')
						for position in positions:
							var positionParts = position.split('-')
							textPositions.push_back({
								"startPosition": positionParts[0],
								"endPosition": positionParts[1]    
							})

						dictEmotes[emoteParts[0]] = textPositions

					dictParsedTags[parsedTag[0]] = dictEmotes
				else:
					dictParsedTags[parsedTag[0]] = null

			'emote-sets':
				# emote-sets=0,33,50,237

				var emoteSetIds = tagValue.split(',')  # Array of emote set IDs.
				dictParsedTags[parsedTag[0]] = emoteSetIds
		# If the tag is in the list of tags to ignore, ignore
		# it; otherwise, add it.

		if not tagsToIgnore.has(parsedTag[0]):
			dictParsedTags[parsedTag[0]] = tagValue

	return dictParsedTags


# Parses the command component of the IRC message.
static func parseCommand(rawCommandComponent):
	var parsedCommand = null
	var commandParts = rawCommandComponent.split(' ')

	match commandParts[0]:
		'JOIN', 'PART', 'NOTICE', 'CLEARCHAT', 'HOSTTARGET', 'PRIVMSG', 'CLEARMSG':
			parsedCommand = {
				"command": commandParts[0],
				"channel": commandParts[1],
			}
		'PING':
			parsedCommand = {
				"command": commandParts[0],
			}
		'CAP':
			parsedCommand = {
				"command": commandParts[0],
				"isCapRequestEnabled": commandParts[2] == 'ACK',
				# The parameters part of the messages contains the 
				# enabled capabilities.
			}
		'GLOBALUSERSTATE':  # Included only if you request the /commands capability.
							# But it has no meaning without also including the /tags capability.
			parsedCommand = {
				"command": commandParts[0],
			}               
		'USERSTATE', 'ROOMSTATE':   # Included only if you request the /commands capability.
									# But it has no meaning without also including the /tags capabilities.
			parsedCommand = {
				"command": commandParts[0],
				"channel": commandParts[1],
			}
		'RECONNECT':  
			push_warning('The Twitch IRC server is about to terminate the connection for maintenance.')
			parsedCommand = {
				"command": commandParts[0],
			}
		"USERNOTICE":
			# announcement msg-id=announcement;msg-param-color=PURPLE
			pass
		'421':
			push_warning("Unsupported IRC command: " + commandParts[2])
			return null
		'001':  # Logged in (successfully authenticated). 
			parsedCommand = {
				"command": commandParts[0],
				"channel": commandParts[1],
			}
		# Ignoring all other numeric messages.
		# 353 Tells you who else is in the chat room you're joining.
		'002', '003', '004', '353', '366', '372', '375', '376':
			#print("numeric message: " + commandParts[0])
			return null
		_:
			if not commandParts[0].empty():
				push_warning("\nUnexpected command: " + commandParts[0] + "\n")
			return null

	return parsedCommand


# Parses the source (nick and host) components of the IRC message.
static func parseSource(rawSourceComponent):
	if not rawSourceComponent:  # Not all messages contain a source
		return null
	else:
		var sourceParts = rawSourceComponent.split('!')
		return {
			"nick": sourceParts[0] if sourceParts.size() == 2 else null,
			"host": sourceParts[1] if sourceParts.size() == 2 else sourceParts[0],
		}


# Parsing the IRC parameters component if it contains a command (e.g., !dice).
static func parseParameters(rawParametersComponent, command) -> Dictionary:
	var idx = 0
	var commandParts = rawParametersComponent.substr(idx + 1).trim_suffix(" ").trim_suffix("\r\n");
	var paramsIdx = commandParts.find(' ')

	if paramsIdx == -1: # no parameters
		command.botCommand = commandParts.substr(0).to_lower()
	else:
		command.botCommand = commandParts.substr(0, paramsIdx).to_lower()
		command.botCommandParams = commandParts.substr(paramsIdx + 1).trim_suffix(" ").trim_suffix("\r\n");
		# TODO: remove extra spaces in parameters string

	return command

