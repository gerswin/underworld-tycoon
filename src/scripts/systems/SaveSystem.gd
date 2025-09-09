extends Node
class_name SaveSystem

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_deleted(slot: int)

const SAVE_FOLDER = "user://saves/"
const SAVE_EXTENSION = ".save"
const MAX_SAVE_SLOTS = 5

var save_data_template = {
	"version": "1.0",
	"timestamp": 0,
	"playtime": 0.0,
	"player_name": "Mayor",
	"game_state": {},
	"economy": {},
	"city_sim": {},
	"shadow_ops": {},
	"risk_system": {},
	"time_manager": {},
	"buildings": [],
	"plots": [],
	"missions": {}
}

func _ready() -> void:
	ensure_save_directory()

func ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")

func save_game(slot: int, save_name: String = "") -> bool:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		print("Invalid save slot: ", slot)
		return false
	
	var save_data = collect_game_data()
	save_data["save_name"] = save_name if save_name != "" else "Save " + str(slot)
	save_data["timestamp"] = Time.get_unix_time_from_system()
	
	var file_path = get_save_file_path(slot)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		print("Failed to open save file: ", file_path)
		save_completed.emit(slot, false)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("Game saved to slot ", slot, " (", save_data["save_name"], ")")
	save_completed.emit(slot, true)
	return true

func load_game(slot: int) -> bool:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		print("Invalid save slot: ", slot)
		return false
	
	var file_path = get_save_file_path(slot)
	if not FileAccess.file_exists(file_path):
		print("Save file not found: ", file_path)
		load_completed.emit(slot, false)
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		print("Failed to open save file: ", file_path)
		load_completed.emit(slot, false)
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse save file: ", file_path)
		load_completed.emit(slot, false)
		return false
	
	var save_data = json.data
	var success = apply_game_data(save_data)
	
	if success:
		print("Game loaded from slot ", slot, " (", save_data.get("save_name", "Unknown"), ")")
	
	load_completed.emit(slot, success)
	return success

func delete_save(slot: int) -> bool:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return false
	
	var file_path = get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		var dir = DirAccess.open("user://saves/")
		var success = dir.remove(get_save_file_name(slot)) == OK
		if success:
			save_deleted.emit(slot)
		return success
	
	return false

func get_save_info(slot: int) -> Dictionary:
	if slot < 1 or slot > MAX_SAVE_SLOTS:
		return {}
	
	var file_path = get_save_file_path(slot)
	if not FileAccess.file_exists(file_path):
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	return {
		"slot": slot,
		"save_name": save_data.get("save_name", "Save " + str(slot)),
		"timestamp": save_data.get("timestamp", 0),
		"playtime": save_data.get("playtime", 0.0),
		"day": save_data.get("time_manager", {}).get("current_day", 1),
		"money": save_data.get("economy", {}).get("dirty_money", 0),
		"version": save_data.get("version", "Unknown")
	}

func get_all_saves_info() -> Array[Dictionary]:
	var saves = []
	for slot in range(1, MAX_SAVE_SLOTS + 1):
		var save_info = get_save_info(slot)
		if save_info.size() > 0:
			saves.append(save_info)
		else:
			# Empty slot placeholder
			saves.append({
				"slot": slot,
				"save_name": "Empty Slot",
				"timestamp": 0,
				"playtime": 0.0,
				"day": 0,
				"money": 0,
				"version": "",
				"is_empty": true
			})
	return saves

func collect_game_data() -> Dictionary:
	var data = save_data_template.duplicate(true)
	
	# Economy data
	if Economy:
		data["economy"] = {
			"clean_money": Economy.clean_money,
			"dirty_money": Economy.dirty_money,
			"income_multipliers": Economy.income_multipliers
		}
	
	# City simulation data
	if CitySim:
		data["city_sim"] = {
			"city_approval": CitySim.city_approval,
			"districts": CitySim.districts,
			"population": CitySim.population
		}
	
	# Shadow operations data
	if ShadowOps:
		data["shadow_ops"] = ShadowOps.get_save_data()
	
	# Risk system data
	if RiskSystem:
		data["risk_system"] = {
			"global_heat": RiskSystem.global_heat,
			"heat_sources": RiskSystem.heat_sources,
			"last_raid_time": RiskSystem.last_raid_time
		}
	
	# Time manager data
	if TimeManager:
		data["time_manager"] = {
			"current_day": TimeManager.current_day,
			"current_hour": TimeManager.current_hour,
			"game_speed": TimeManager.game_speed,
			"is_paused": TimeManager.is_paused
		}
	
	# Buildings data
	var main_scene = get_tree().get_root().get_node_or_null("Main")
	if main_scene:
		data["buildings"] = collect_buildings_data(main_scene)
		
		# Building plots data
		if main_scene.building_plots:
			data["plots"] = main_scene.building_plots.plots
	
	# Mission system data
	if main_scene and main_scene.mission_system:
		data["missions"] = {
			"active_missions": main_scene.mission_system.active_missions,
			"completed_missions": main_scene.mission_system.completed_missions
		}
	
	# Game metadata
	data["playtime"] = GameManager.get_playtime() if GameManager.has_method("get_playtime") else 0.0
	
	return data

func collect_buildings_data(main_scene: Node) -> Array:
	var buildings_data = []
	
	if main_scene.buildings_container:
		for building in main_scene.buildings_container.get_children():
			if building.has_meta("business_data"):
				var business_data = building.get_meta("business_data")
				buildings_data.append({
					"business_data": business_data,
					"position": building.position
				})
	
	return buildings_data

func apply_game_data(data: Dictionary) -> bool:
	# Validate save data
	if not data.has("version"):
		print("Invalid save data: missing version")
		return false
	
	# Apply economy data
	if data.has("economy") and Economy:
		var economy_data = data["economy"]
		Economy.clean_money = economy_data.get("clean_money", 75000.0)
		Economy.dirty_money = economy_data.get("dirty_money", 20000.0)
		Economy.income_multipliers = economy_data.get("income_multipliers", {"current": 1.0})
		Economy.money_changed.emit(Economy.clean_money, Economy.dirty_money)
	
	# Apply city simulation data
	if data.has("city_sim") and CitySim:
		var city_data = data["city_sim"]
		CitySim.city_approval = city_data.get("city_approval", 60.0)
		CitySim.districts = city_data.get("districts", [])
		CitySim.population = city_data.get("population", 50000)
		CitySim.approval_changed.emit(CitySim.city_approval)
	
	# Apply shadow operations data
	if data.has("shadow_ops") and ShadowOps:
		ShadowOps.load_save_data(data["shadow_ops"])
	
	# Apply risk system data
	if data.has("risk_system") and RiskSystem:
		var risk_data = data["risk_system"]
		RiskSystem.global_heat = risk_data.get("global_heat", 0.0)
		RiskSystem.heat_sources = risk_data.get("heat_sources", {})
		RiskSystem.last_raid_time = risk_data.get("last_raid_time", 0)
		RiskSystem.heat_changed.emit(RiskSystem.global_heat)
	
	# Apply time manager data
	if data.has("time_manager") and TimeManager:
		var time_data = data["time_manager"]
		TimeManager.current_day = time_data.get("current_day", 1)
		TimeManager.current_hour = time_data.get("current_hour", 6)
		TimeManager.game_speed = time_data.get("game_speed", 1.0)
		TimeManager.is_paused = time_data.get("is_paused", false)
	
	# Apply buildings data
	var main_scene = get_tree().get_root().get_node_or_null("Main")
	if main_scene and data.has("buildings"):
		restore_buildings(main_scene, data["buildings"])
	
	# Apply building plots data
	if main_scene and main_scene.building_plots and data.has("plots"):
		main_scene.building_plots.plots = data["plots"]
	
	# Apply mission system data
	if main_scene and main_scene.mission_system and data.has("missions"):
		var mission_data = data["missions"]
		main_scene.mission_system.active_missions = mission_data.get("active_missions", [])
		main_scene.mission_system.completed_missions = mission_data.get("completed_missions", [])
	
	print("Game state restored successfully")
	return true

func restore_buildings(main_scene: Node, buildings_data: Array) -> void:
	# Clear existing buildings
	if main_scene.buildings_container:
		for child in main_scene.buildings_container.get_children():
			child.queue_free()
	
	# Wait for deletion to complete
	await get_tree().process_frame
	
	# Restore buildings
	for building_data in buildings_data:
		var business_data = building_data.get("business_data", {})
		var _position = building_data.get("position", Vector2.ZERO)  # Position stored in business_data
		
		if business_data.size() > 0:
			main_scene.create_building_visual(business_data)

func auto_save() -> void:
	# Auto-save to a dedicated auto-save slot (slot 0)
	save_game_to_path(get_auto_save_path(), "Auto Save")

func save_game_to_path(file_path: String, save_name: String) -> bool:
	var save_data = collect_game_data()
	save_data["save_name"] = save_name
	save_data["timestamp"] = Time.get_unix_time_from_system()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		print("Failed to create auto-save: ", file_path)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	return true

func get_save_file_path(slot: int) -> String:
	return SAVE_FOLDER + get_save_file_name(slot)

func get_save_file_name(slot: int) -> String:
	return "save_" + str(slot) + SAVE_EXTENSION

func get_auto_save_path() -> String:
	return SAVE_FOLDER + "auto_save" + SAVE_EXTENSION

func format_timestamp(timestamp: int) -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%d/%02d/%02d %02d:%02d" % [
		datetime.year,
		datetime.month, 
		datetime.day,
		datetime.hour,
		datetime.minute
	]

func format_playtime(seconds: float) -> String:
	var hours = int(seconds / 3600.0)
	var remaining_seconds = int(seconds) % 3600
	var minutes = int(remaining_seconds / 60.0)
	return "%02d:%02d" % [hours, minutes]
