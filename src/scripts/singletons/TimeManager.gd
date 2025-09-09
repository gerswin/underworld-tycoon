extends Node

signal hour_passed(hour: int)
signal day_changed(day: int)
signal cycle_changed(is_day: bool)

var current_hour: int = 6  # Start at 6 AM
var current_day: int = 1
var time_speed: float = 30.0  # Faster for MVP testing - 1 second = 2 minutes in-game
var accumulated_time: float = 0.0
var is_paused: bool = false

var day_start_hour: int = 6
var night_start_hour: int = 18

func _ready() -> void:
	set_process(true)
	print("TimeManager initialized - Day ", current_day, " Hour: ", current_hour)

func _process(delta: float) -> void:
	if !is_paused and GameManager.current_state == GameManager.GameState.PLAYING:
		accumulated_time += delta * time_speed
		
		if accumulated_time >= 60.0:  # One hour has passed
			accumulated_time -= 60.0
			advance_hour()

func advance_hour() -> void:
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		advance_day()
	
	hour_passed.emit(current_hour)
	check_day_night_cycle()

func advance_day() -> void:
	current_day += 1
	day_changed.emit(current_day)
	print("Day ", current_day, " has begun")

func check_day_night_cycle() -> void:
	var was_day = is_day_time()
	var is_day_now = is_day_time()
	
	if current_hour == day_start_hour:
		cycle_changed.emit(true)
		GameManager.toggle_day_night()
	elif current_hour == night_start_hour:
		cycle_changed.emit(false)
		GameManager.toggle_day_night()

func is_day_time() -> bool:
	return current_hour >= day_start_hour and current_hour < night_start_hour

func get_time_string() -> String:
	var hour_str = str(current_hour).pad_zeros(2)
	var period = "AM" if current_hour < 12 else "PM"
	var display_hour = current_hour if current_hour <= 12 else current_hour - 12
	if display_hour == 0:
		display_hour = 12
	return str(display_hour) + ":00 " + period

func get_formatted_date() -> String:
	return "Day " + str(current_day) + " - " + get_time_string()

func set_time_speed(multiplier: float) -> void:
	time_speed = clamp(multiplier, 0.0, 300.0)  # Max 5 minutes per second

func pause_time(pause: bool) -> void:
	is_paused = pause

func skip_to_morning() -> void:
	while current_hour != day_start_hour:
		advance_hour()

func skip_to_night() -> void:
	while current_hour != night_start_hour:
		advance_hour()

func get_save_data() -> Dictionary:
	return {
		"current_hour": current_hour,
		"current_day": current_day,
		"time_speed": time_speed
	}

func load_save_data(data: Dictionary) -> void:
	current_hour = data.get("current_hour", 6)
	current_day = data.get("current_day", 1)
	time_speed = data.get("time_speed", 60.0)