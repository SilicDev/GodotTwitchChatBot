@icon("res://addons/godot_twitch_bot/assets/icon.png")
class_name TwitchAPI
extends RefCounted
## For details see https://dev.twitch.tv/docs/api/reference
## This is not meant to be an extensive API, and before using any call
## check the documentation.
## Note that not all API endpoints are implemented at this point


var client := HTTPClient.new()
var headers := []
var base_headers := [
	"User-Agent: Pirulo/1.0 (Godot)",
	"Accept: application/json",
]
var mutex := Mutex.new()


func connect_to_twitch(args = null) -> bool:
	var err := client.connect_to_host("https://api.twitch.tv")
	if err:
		return false
	print("Connecting...")
	while (client.get_status() == HTTPClient.STATUS_CONNECTING or 
			client.get_status() == HTTPClient.STATUS_RESOLVING):
		client.poll()
		printraw(".")
		#if not OS.has_feature("web"):
		OS.delay_msec(500)
		#else:
			#await Engine.get_main_loop().process_frame
	return true

func disconnect_from_twitch() -> void:
	client.close()

## Start Commercial
## requires: token scope channel:edit:commercial
func start_commercial(broadcaster_id: String, length: int) -> Dictionary:
	var data = {
		"broadcaster_id": broadcaster_id,
		"length": length,
	}
	var err := _request(
			HTTPClient.METHOD_POST, 
			"/helix/channels/commercial",
			headers + base_headers + ["Content-Type: application/json"], 
			JSON.stringify(data)
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Extension Analytics

# Get Game Analytics

# Get Bits Leaderboard

# Get Cheermotes

# Get Extension Transactions


## Get Channel Info
func get_channel_info(broadcaster_ids: PackedStringArray) -> Dictionary:
	var url = "/helix/channels?broadcaster_id=" + broadcaster_ids[0]
	for i in range(1, broadcaster_ids.size()):
		url += "&broadcaster_id=" + broadcaster_ids[i]
	var err := _request(
			HTTPClient.METHOD_GET, 
			url, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Modify Channel Info
## requires: token scope channel:manage:broadcast
func modify_channel_info(
		broadcaster_id: String, 
		game_id = null, 
		language = null, 
		title = null, 
		delay := -1
) -> Dictionary:
	var data = {}
	if game_id:
		data["game_id"] = game_id
	if language:
		data["broadcaster_language"] = language
	if title and not title.is_empty():
		data["title"] = title
	if delay >= 0:
		data["delay"] = delay
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(
			HTTPClient.METHOD_PATCH, 
			"/helix/channels?broadcaster_id=" + broadcaster_id, 
			h, 
			JSON.stringify(data)
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Channel Editors

# Create Custom Rewards
# requires: token scope channel:manage:redemptions

# Delete Custom Reward
# requires: token scope channel:manage:redemptions

# Get Custom Reward
# requires: token scope channel:read:redemptions

# Get Custom Reward Redemption

# Delete Update Reward
# requires: token scope channel:manage:redemptions

# Update Redemption Status
# requires: token scope channel:manage:redemptions

# Get Charity Campaign
# requires: token scope channel:read:charity


## Get Channel Emotes
func get_channel_emotes(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/emotes?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Global Emotes
func get_global_emotes() -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/emotes/global", 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Emote Sets
func get_emote_set(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/emotes?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Channel Chat Badges
func get_channel_chat_badges(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/badges?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Global Chat Badges
func get_global_chat_badges() -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/badges/global", 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Chat Settings
## might require: token scope moderator:read:chat_settings
func get_chat_settings(broadcaster_id: String, mod_id: String = "") -> Dictionary:
	var url = "/helix/chat/settings?broadcaster_id=" + broadcaster_id + \
			("&moderator_id=" + mod_id) if not mod_id.is_empty() else ""
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Update Chat Settings
## requires: token scope moderator:manage:chat_settings
func update_chat_settings(
		broadcaster_id: String, 
		settings: Dictionary, 
		mod_id: String = ""
) -> Dictionary:
	var url = "/helix/chat/settings?broadcaster_id=" + broadcaster_id + \
			("&moderator_id=" + mod_id) if not mod_id.is_empty() else ""
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(HTTPClient.METHOD_GET, url, h, JSON.stringify(settings))
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Send Chat Announcement
## requires: token scope moderator:manage:announcements
func send_chat_announcement(
		broadcaster_id: String, 
		mod_id: String, 
		message: String, 
		color := "primary"
) -> Dictionary:
	var url = "/helix/chat/announcements?broadcaster_id=" + broadcaster_id + \
			"&moderator_id=" + mod_id
	var h := headers + base_headers + ["Content-Type: application/json"]
	var data := {"message":message,"color":color}
	var err := _request(HTTPClient.METHOD_POST, url, h, JSON.stringify(data))
	var response =  _get_response() #await _get_response()
	if not response.is_empty():
		var test_json_conv = JSON.new()
		err = test_json_conv.parse(response)
		return test_json_conv.get_data()
	return {}

## Send A Shoutout
## requires: token scope moderator:manage:shoutouts
func send_shoutout(
		from_broadcaster_id: String, 
		to_broadcaster_id: String, 
		mod_id: String
) -> Dictionary:
	var url = "/helix/chat/shoutouts?from_broadcaster_id=" + from_broadcaster_id + \
			"&to_broadcaster_id=" + to_broadcaster_id + "&moderator_id=" + mod_id
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(HTTPClient.METHOD_POST, url, h)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get User Chat Color
func get_user_chat_color(user_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/color?user_id=" + user_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Update User Chat Color
## requires: token scope user:manage:chat_color
func update_user_chat_color(user_id: String, color: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_PUT, 
			"/helix/chat/color?user_id=" + user_id + "&color=" + color.uri_encode(), 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Create Clip
## requires: token scope clips:edit
func create_clip(broadcaster_id: String, delay := false) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_POST, 
			"/helix/clips?broadcaster_id=" + broadcaster_id + "&has_delay=" + str(delay), 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Clips
func get_clips_by_broadcaster(
		id: String, 
		before := "", 
		after := "", 
		started_at := "", 
		ended_at := "", 
		first := 20
) -> Dictionary:
	var optional_query := ""
	if before:
		optional_query += "&before=" + before
	if after:
		optional_query += "&after=" + after
	if started_at:
		optional_query += "&started_at=" + started_at
	if ended_at:
		optional_query += "&ended_at=" + ended_at
	if first:
		optional_query += "&first=" + str(first)
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/clips?broadcaster_id=" + id + optional_query, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Clips
func get_clips_by_game(
		id: String, 
		before := "", 
		after := "", 
		started_at := "", 
		ended_at := "", 
		first := 20
) -> Dictionary:
	var optional_query := ""
	if before:
		optional_query += "&before=" + before
	if after:
		optional_query += "&after=" + after
	if started_at:
		optional_query += "&started_at=" + started_at
	if ended_at:
		optional_query += "&ended_at=" + ended_at
	if first:
		optional_query += "&first=" + str(first)
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/chat/clips?game_id=" + id + optional_query, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Clips
func get_clips_by_ids(
		ids: PackedStringArray, 
		started_at := "", 
		ended_at := "", 
		first := 20
) -> Dictionary:
	var optional_query := ""
	if started_at:
		optional_query += "&started_at=" + started_at
	if ended_at:
		optional_query += "&ended_at=" + ended_at
	if first:
		optional_query += "&first=" + str(first)
	var url = "/helix/chat/clips?id=" + ids[0]
	for i in range(1, ids.size()):
		url += "&id=" + ids[i]
	var err := _request(HTTPClient.METHOD_GET, url + optional_query, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Code Status

# Get Drops Entitlements
# requires: ownership of the game

# Update Drops Entitlements
# requires: ownership of the game

# Redeem Code
# requires: Twitch approval

# Get Extension Configuration Segment
# requires: signed JWT

# Set Extension Configuration Segment
# requires: signed JWT

# Set Extension Required Segment
# requires: signed JWT

# Send Extension PubSub Message
# requires: signed JWT


## Get Extension Live Channels
func get_extension_live_channels(extension_id: String, after := "", first := 20) -> Dictionary:
	var optional_query := ""
	if after:
		optional_query += "&after=" + after
	if first:
		optional_query += "&first=" + str(first)
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/extensions/live?extension_id=" + extension_id + optional_query, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Extension Secrets
# requires: signed JWT

# Create Extension Secrets
# requires: signed JWT

# Send Extension Chat Message
# requires: signed JWT

# Get Extensions
# requires: signed JWT

## Get Released Extensions
func get_released_extensions(extension_id: String, extension_version := "") -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/extensions/released?extension_id=" + extension_id + 
					("&extension_version=" + extension_version) if extension_version else "", 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Extension Bits Products

# Update Extension Bits Product

# Create EventSub Subscription
# requires: various token scopes based on requested subscripton

# Delete EventSub Subscription

# Get EventSub Subscriptions

# Get Top Games

## Get Games
func get_games_by_name(game_names: PackedStringArray) -> Dictionary:
	var url = "/helix/games?name=" + game_names[0]
	for i in range(1, game_names.size()):
		url += "&name=" + game_names[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Games
func get_games_by_id(ids: PackedStringArray) -> Dictionary:
	var url = "/helix/games?id=" + ids[0]
	for i in range(1, ids.size()):
		url += "&id=" + ids[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Games
func get_games(game_names: PackedStringArray, ids: PackedStringArray) -> Dictionary:
	if game_names.is_empty():
		return await get_games_by_id(ids)
	if ids.is_empty():
		return await get_games_by_name(game_names)
	var url = "/helix/games?name=" + game_names[0]
	for i in range(1, game_names.size()):
		url += "&name=" + game_names[i]
	for i in range(1, ids.size()):
		url += "&id=" + ids[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}

# Get Creator Goals
# requires: token scope channel:read:goals, oauth must be for broadcaster

# Get Hype Train Events
# requires: token scope channel:read:hype_train

# Check AutoMod Status
# requires: token scope moderation:read

# Manage Held AutoMod Messages
# requires: token scope moderator:manage:automod

# Get AutoMod Settings
# requires: token scope moderator:read:automod_settings

# Update AutoMod Settings
# requires: token scope moderator:manage:automod_settings

# Get Banned Users
# requires: token scope moderation:read

## Ban User
## requires: token scope moderator:manage:banned_users
func ban_user(
		broadcaster_id: String, 
		moderator_id: String, 
		user_id: String, 
		reason := "", 
		duration := 0
) -> Dictionary:
	var data = {"data":{}}
	if user_id:
		data.data["user_id"] = user_id
	if duration > 0:
		data.data["duration"] = duration
	if reason:
		data.data["reason"] = reason
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(
			HTTPClient.METHOD_POST, 
			"/helix/moderation/bans?broadcaster_id=" + broadcaster_id + "&moderator_id=" + moderator_id, 
			h,
			JSON.stringify(data)
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Unban User
## requires: token scope moderator:manage:banned_users
func unban_user(
		broadcaster_id: String, 
		moderator_id: String, 
		user_id: String
):
	var err := _request(
			HTTPClient.METHOD_DELETE, 
			"/helix/moderation/bans?broadcaster_id=" + broadcaster_id + "&moderator_id=" + 
					moderator_id + "&user_id=" + user_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Blocked Terms
# requires: token scope moderator:read:blocked_terms

# Add Blocked Term
# requires: token scope moderator:manage:blocked_terms

# Remove Blocked Term
# requires: token scope moderator:manage:blocked_terms


## Delete Chat Messages
## requires: token scope moderator:manage:chat_messages
func delete_chat_messages(broadcaster_id: String, moderator_id: String, message_id := "") -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_DELETE, 
			"/helix/moderation/chat?broadcaster_id=" + broadcaster_id + "&moderator_id=" + 
					moderator_id + ("&message_id=" + message_id) if message_id else "", 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get Moderators
# requires: either token scope moderation:read or token scope channel:manage:moderators

# Add Channel Moderator
# requires: token scope channel:manage:moderators

# Remove Channel Moderator
# requires: token scope channel:manage:moderators

# Get VIPs
# requires: either token scope channel:read:vips or token scope channel:manage:vips

# Add Channel VIP
# requires: token scope channel:manage:vips

# Remove Channel VIP
# requires: token scope channel:manage:vips

# Get Polls
# requires: token scope channel:read:polls

# Create Poll
# requires: token scope channel:manage:polls

# End Poll
# requires: token scope channel:manage:polls

# Get Predictions
# requires: token scope channel:read:predictions

# Create Prediction
# requires: token scope channel:manage:predictions

# End Prediction
# requires: token scope channel:manage:predictions

# Start a raid
# requires: token scope channel:manage:raids

# Cancel a raid
# requires: token scope channel:manage:raids


## Get Channel Stream Schedule
func get_channel_stream_schedule(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/schedule?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Channel iCalendar
func get_channel_icalendar(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/schedule/icalendar?broadcaster_id=" + broadcaster_id, 
			base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Update Channel Stream Schedule
# requires: token scope channel:manage:schedule

# Create Channel Stream Schedule Segment
# requires: token scope channel:manage:schedule

# Update Channel Stream Schedule Segment
# requires: token scope channel:manage:schedule

# Delete Channel Stream Schedule Segment
# requires: token scope channel:manage:schedule

# Search Channels

# Get Soundtrack Current Track

# Get Soundtrack Playlist

# Get Soundtrack Playlists

# Get Stream Key
# requires: token scope channel:read:stream_key

# Get Streams

# Get Followed Streams
# requires: token scope user:read:follows

# Create Stream Marker
# requires: token scope channel:manage:broadcast

# Get Stream Markers
# requires: token scope user:read:broadcast

# Get Broadcaster Subscriptions
# requires: token scope channel:read:subscriptions

# Check User Subscription
# requires: token scope user:read:subscriptions

# Get All Stream Tags

## Get Stream Tags
## Does not include custom tags
func get_stream_tags(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/streams/tags?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Replace Stream Tags
## Does not include custom tags
## requires: token scope channel:manage:broadcast
func replace_stream_tags(broadcaster_id: String, tag_ids: PackedStringArray) -> Dictionary:
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(
			HTTPClient.METHOD_PUT, 
			"/helix/streams/tags?broadcaster_id=" + broadcaster_id, 
			h,
			JSON.stringify(tag_ids)
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Channel Teams
func get_channel_teams(broadcaster_id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/teams/channel?broadcaster_id=" + broadcaster_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Teams
func get_teams_by_name(name: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/teams?name=" + name, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Teams
func get_teams_by_id(id: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/teams?id=" + id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users
## might require: token scope user:read:email 
func get_users_by_name(user_names: PackedStringArray) -> Dictionary:
	var url = "/helix/users?login=" + user_names[0]
	for i in range(1, user_names.size()):
		url += "&login=" + user_names[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users
## might require: token scope user:read:email 
func get_users_by_id(ids: PackedStringArray) -> Dictionary:
	var url = "/helix/users?id=" + ids[0]
	for i in range(1, ids.size()):
		url += "&id=" + ids[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users
## might require: token scope user:read:email 
func get_users(user_names: PackedStringArray, ids: PackedStringArray) -> Dictionary:
	if user_names.is_empty():
		return get_users_by_id(ids)
	if ids.is_empty():
		return get_users_by_name(user_names)
	var url = "/helix/users?login=" + user_names[0]
	for i in range(1, user_names.size()):
		url += "&login=" + user_names[i]
	for i in range(1, ids.size()):
		url += "&id=" + ids[i]
	var err := _request(HTTPClient.METHOD_GET, url, headers + base_headers)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Update User
## requires: token scope user:edit
## might require: token scope user:read:email
func update_user(description: String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_PUT, 
			"/helix/users?description=" + description, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users Follows
func get_users_follows_from(from_id : String, after := "", first := 20) -> Dictionary:
	var optional_query := ""
	if after:
		optional_query += "&after=" + after
	if first:
		optional_query += "&first=" + str(first)
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/users/follows?from_id=" + from_id + optional_query, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users Follows
func get_users_follows_to(to_id : String, after := "", first := 20) -> Dictionary:
	var optional_query := ""
	if after:
		optional_query += "&after=" + after
	if first:
		optional_query += "&first=" + str(first)
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/users/follows?to_id=" + to_id + optional_query, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


## Get Users Follows
func get_users_follows_from_to(from_id : String, to_id : String) -> Dictionary:
	var err := _request(
			HTTPClient.METHOD_GET, 
			"/helix/users/follows?from_id=" + from_id + "&to_id=" + to_id, 
			headers + base_headers
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


# Get User Block List
# requires: token scope user:read:blocked_users

# Block User
# requires: token scope user:manage:blocked_users

# Unblock User
# requires: token scope user:manage:blocked_users

# Get User Extensions
# requires: token scope user:read:broadcast

# Get User Active Extensions
# might require: token scope user:read:broadcast or user:edit:broadcast

# Update User Extensions
# requires: token scope user:edit:broadcast

# Get Videos

# Delete Videos
# requires: token scope channel:manage:videos

## Send Whisper
## requires: token scope user:manage:whispers, verified phone number
func send_whisper(from_id : String, to_id : String, message: String) -> Dictionary:
	var h := headers + base_headers + ["Content-Type: application/json"]
	var err := _request(
			HTTPClient.METHOD_POST, 
			"/helix/whispers?from_user_id=" + from_id + "&to_user_id=" + to_id, 
			h,
			JSON.stringify({"message": message})
	)
	if not err:
		return _get_response() #return await _get_response()
	return {}


func _to_string() -> String:
	return "[TwitchAPI:" + str(get_instance_id()) + "]"


## Helper functions
func _request(method: int, url: String, request_headers: PackedStringArray, body := "") -> int:
	mutex.lock()
	client.poll()
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		disconnect_from_twitch()
		connect_to_twitch()
	print("Requesting %s ..." % url)
	return client.request(method, url, request_headers, body)


func _get_response() -> Dictionary:
	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		# Keep polling for as long as the request is being processed.
		client.poll()
		printraw(".")
		if false and OS.has_feature("web"):
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			#await Engine.get_main_loop().process_frame
			pass
		else:
			OS.delay_msec(500)
	
	if client.has_response():
		var status = client.get_response_code()
		# If there is a response...
		
		var rb = PackedByteArray() # Array that will hold the data.
		
		while client.get_status() == HTTPClient.STATUS_BODY:
			# While there is body left to be read
			client.poll()
			# Get a chunk.
			var chunk = client.read_response_body_chunk()
			if chunk.size() == 0:
				if true or not OS.has_feature("web"):
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(100)
				else:
					#await Engine.get_main_loop().process_frame
					pass
			else:
				rb.append_array(chunk) # Append to read buffer.
		# Done!
		
		var message = rb.get_string_from_utf8()
		var test_json_conv = JSON.new()
		var err := test_json_conv.parse(message)
		var result = test_json_conv.get_data()
		if not err:
			if not "status" in result.keys():
				result["status"] = status
			mutex.unlock()
			print(result)
			return result
		var data = {
			"message": message,
			"status" : status,
		}
		push_warning(data)
		mutex.unlock()
		return data
	mutex.unlock()
	return {}
