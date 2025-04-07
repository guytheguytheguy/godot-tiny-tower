extends Node
# Game Manager - Singleton for managing game state

signal game_state_changed(state)
signal score_updated(score)
signal moves_updated(moves)
signal timer_updated(time)
signal level_selected(level_id)

enum GameState {MENU, PLAYING, PAUSED, GAME_OVER, LEVEL_COMPLETE}

var current_state: int = GameState.MENU
var score: int = 0
var moves: int = 0
var timer: float = 0
var timer_running: bool = false
var game_data: Dictionary = {}
var current_level_id: String = ""
var stars_earned: int = 0

# Game configuration
var config: Dictionary = {
	"gravity": 25.0,
	"block_fall_speed": 5.0,
	"block_rotation_speed": 1.0,
	"game_speed": 1.0
}

func _ready():
	reset_game_state()
	load_settings()

func _process(delta):
	if timer_running:
		timer += delta
		emit_signal("timer_updated", timer)

func start_game(level_id: String) -> void:
	current_level_id = level_id
	reset_game_state()
	set_state(GameState.PLAYING)
	timer_running = true

func select_level(level_id: String) -> void:
	current_level_id = level_id
	emit_signal("level_selected", level_id)

func get_selected_level() -> String:
	return current_level_id

func reset_game_state() -> void:
	score = 0
	emit_signal("score_updated", score)
	moves = 0
	emit_signal("moves_updated", moves)
	timer = 0
	emit_signal("timer_updated", timer)
	timer_running = false
	stars_earned = 0

func set_state(new_state: int) -> void:
	if current_state != new_state:
		current_state = new_state
		emit_signal("game_state_changed", current_state)
		
		# Handle state-specific actions
		match current_state:
			GameState.PLAYING:
				Engine.time_scale = config.game_speed
				timer_running = true
			GameState.PAUSED:
				Engine.time_scale = 0.0
				timer_running = false
			GameState.GAME_OVER, GameState.LEVEL_COMPLETE:
				timer_running = false
			GameState.MENU:
				Engine.time_scale = 1.0
				timer_running = false

func get_state() -> int:
	return current_state

func add_score(points: int) -> void:
	score += points
	emit_signal("score_updated", score)

func add_move() -> void:
	moves += 1
	emit_signal("moves_updated", moves)

func complete_level(level_id: String, stars: int, final_score: int, time_taken: float, move_count: int) -> void:
	timer_running = false
	current_level_id = level_id
	stars_earned = stars
	score = final_score
	timer = time_taken
	moves = move_count
	
	# Store level progress if DataManager is available
	if DataManager != null and DataManager.has_method("save_level_progress"):
		DataManager.save_level_progress(current_level_id, {
			"completed": true,
			"score": final_score,
			"stars": stars_earned,
			"moves": moves,
			"time": timer
		})
	
	set_state(GameState.LEVEL_COMPLETE)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		set_state(GameState.PAUSED)
	elif current_state == GameState.PAUSED:
		set_state(GameState.PLAYING)

func game_over() -> void:
	set_state(GameState.GAME_OVER)

func return_to_menu() -> void:
	set_state(GameState.MENU)

func load_settings() -> void:
	if DataManager == null or not DataManager.has_method("load_settings"):
		return
		
	var settings = DataManager.load_settings()
	if settings:
		if settings.has("sound_volume") and SoundManager != null and SoundManager.has_method("set_sound_volume"):
			SoundManager.set_sound_volume(settings["sound_volume"])
		if settings.has("music_volume") and SoundManager != null and SoundManager.has_method("set_music_volume"):
			SoundManager.set_music_volume(settings["music_volume"])
		if settings.has("game_speed"):
			config.game_speed = settings["game_speed"]
