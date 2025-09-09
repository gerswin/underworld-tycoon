extends Node

signal game_started
signal game_paused(is_paused: bool)
signal game_over(won: bool)
signal election_triggered
signal day_night_changed(is_day: bool)

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	ELECTION,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var is_day: bool = true
var game_speed: float = 1.0
var current_day: int = 1
var time_until_election: float = 1200.0  # 20 minutos en segundos

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("GameManager initialized")

func start_game() -> void:
	current_state = GameState.PLAYING
	current_day = 1
	is_day = true
	time_until_election = 1200.0
	game_started.emit()
	print("Game started")

func pause_game(pause: bool) -> void:
	if current_state == GameState.PLAYING:
		get_tree().paused = pause
		current_state = GameState.PAUSED if pause else GameState.PLAYING
		game_paused.emit(pause)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if current_state == GameState.PLAYING:
			pause_game(true)
		elif current_state == GameState.PAUSED:
			pause_game(false)

func trigger_election() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.ELECTION
		election_triggered.emit()
		print("Election triggered!")
		
func check_election_results(approval: float, heat: float) -> bool:
	var won = approval > 50.0 and heat < 70.0
	end_game(won)
	return won

func end_game(won: bool) -> void:
	current_state = GameState.GAME_OVER
	game_over.emit(won)
	print("Game Over - Won: ", won)

func toggle_day_night() -> void:
	is_day = !is_day
	day_night_changed.emit(is_day)
	if !is_day:
		current_day += 1

func set_game_speed(speed: float) -> void:
	game_speed = clamp(speed, 0.0, 3.0)
	Engine.time_scale = game_speed

func get_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"is_day": is_day,
		"time_until_election": time_until_election,
		"game_speed": game_speed
	}

func load_save_data(data: Dictionary) -> void:
	current_day = data.get("current_day", 1)
	is_day = data.get("is_day", true)
	time_until_election = data.get("time_until_election", 1200.0)
	game_speed = data.get("game_speed", 1.0)