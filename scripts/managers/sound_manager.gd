extends Node
# Sound Manager - Handles all game audio

var sound_players = {}
var music_player: AudioStreamPlayer = null
var sound_volume: float = 0.8
var music_volume: float = 0.7
var sound_enabled: bool = true
var music_enabled: bool = true

# Sound effect paths
const SOUNDS = {
	"click": "res://assets/sounds/ui/click.wav",
	"place_block": "res://assets/sounds/game/place_block.wav",  # Keep for backward compatibility
	"remove_block": "res://assets/sounds/game/place_block.wav", # Reuse existing sound for now
	"select_block": "res://assets/sounds/ui/click.wav",         # Reuse existing sound for block selection
	"block_hit": "res://assets/sounds/game/block_hit.wav",
	"block_fall": "res://assets/sounds/game/block_fall.wav",
	"tower_collapse": "res://assets/sounds/game/block_fall.wav", # Reuse existing sound
	"level_complete": "res://assets/sounds/game/level_complete.wav",
	"game_over": "res://assets/sounds/game/game_over.wav",
	"star_earned": "res://assets/sounds/game/star_earned.wav",
}

# Music tracks
const MUSIC = {
	"menu": "res://assets/music/menu_theme.mp3",
	"gameplay": "res://assets/music/gameplay_theme.mp3",
	"bgm_victory": "res://assets/music/victory_theme.mp3",
}

func _ready():
	# Create AudioStreamPlayers for sound effects (pool of players)
	for i in range(8):  # Create a pool of players for concurrent sounds
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.volume_db = linear_to_db(sound_volume)
		add_child(player)
		sound_players[player] = false  # false means it's available
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)
	
	# Load user preferences
	var settings = null
	if DataManager != null and DataManager.has_method("load_settings"):
		settings = DataManager.load_settings()
	
	if settings:
		if settings.has("sound_enabled"):
			sound_enabled = settings["sound_enabled"]
		if settings.has("music_enabled"):
			music_enabled = settings["music_enabled"]
		if settings.has("sound_volume"):
			set_sound_volume(settings["sound_volume"])
		if settings.has("music_volume"):
			set_music_volume(settings["music_volume"])

# Play a sound effect
func play(sound_name: String) -> void:
	if not sound_enabled or not SOUNDS.has(sound_name):
		return
	
	# Find an available player
	var player = get_available_player()
	if player:
		var stream = load(SOUNDS[sound_name])
		if stream:
			player.stream = stream
			player.play()
			sound_players[player] = true  # Mark as in use
			
			# Listen for completion to mark player as available again
			player.connect("finished", _on_sound_finished.bind(player))

# Play background music
func play_music(track_name: String) -> void:
	if not music_enabled or not MUSIC.has(track_name):
		return
	
	if music_player.playing and music_player.stream and music_player.stream.resource_path == MUSIC[track_name]:
		return  # Already playing this track
	
	var stream = load(MUSIC[track_name])
	if stream:
		music_player.stream = stream
		music_player.play()

# Stop the current music
func stop_music() -> void:
	if music_player.playing:
		music_player.stop()

# Set sound volume (0.0 to 1.0)
func set_sound_volume(volume: float):
	sound_volume = clamp(volume, 0.0, 1.0)
	
	# Update volume for all sound players
	for player in sound_players.keys():
		if player is AudioStreamPlayer:
			player.volume_db = linear_to_db(sound_volume)
	
	# Save to settings
	var settings = null
	if DataManager != null and DataManager.has_method("load_settings"):
		settings = DataManager.load_settings() or {}
	else:
		settings = {}
	
	if settings is Dictionary:
		settings["sound_volume"] = sound_volume
		if DataManager != null and DataManager.has_method("save_settings"):
			DataManager.save_settings(settings)

# Set music volume (0.0 to 1.0)
func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	
	# Update music player volume
	if music_player != null:
		music_player.volume_db = linear_to_db(music_volume)
	
	# Save to settings
	var settings = null
	if DataManager != null and DataManager.has_method("load_settings"):
		settings = DataManager.load_settings() or {}
	else:
		settings = {}
	
	if settings is Dictionary:
		settings["music_volume"] = music_volume
		if DataManager != null and DataManager.has_method("save_settings"):
			DataManager.save_settings(settings)

# Toggle sound effects
func toggle_sound() -> void:
	sound_enabled = !sound_enabled
	
	# Save to settings
	var settings = null
	if DataManager != null and DataManager.has_method("load_settings"):
		settings = DataManager.load_settings() or {}
	else:
		settings = {}
	
	if settings is Dictionary:
		settings["sound_enabled"] = sound_enabled
		if DataManager != null and DataManager.has_method("save_settings"):
			DataManager.save_settings(settings)

# Toggle music
func toggle_music() -> void:
	music_enabled = !music_enabled
	
	if music_enabled and music_player.stream:
		music_player.play()
	elif not music_enabled and music_player.playing:
		music_player.stop()
	
	# Save to settings
	var settings = null
	if DataManager != null and DataManager.has_method("load_settings"):
		settings = DataManager.load_settings() or {}
	else:
		settings = {}
	
	if settings is Dictionary:
		settings["music_enabled"] = music_enabled
		if DataManager != null and DataManager.has_method("save_settings"):
			DataManager.save_settings(settings)

# Find an available sound player from the pool
func get_available_player() -> AudioStreamPlayer:
	for player in sound_players.keys():
		if not sound_players[player]:  # If player is available
			return player
	
	# If all players are in use, pick the oldest one that's playing
	var oldest_player = sound_players.keys()[0]
	return oldest_player

# Signal handler when a sound finishes playing
func _on_sound_finished(player: AudioStreamPlayer) -> void:
	sound_players[player] = false  # Mark player as available again
	player.disconnect("finished", _on_sound_finished)
