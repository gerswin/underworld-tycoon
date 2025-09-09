extends Node
class_name MissionSystem

signal mission_completed(mission: Dictionary)
signal mission_failed(mission: Dictionary)
signal new_mission_available(mission: Dictionary)

var active_missions: Array[Dictionary] = []
var completed_missions: Array[Dictionary] = []
var available_missions: Array[Dictionary] = []

var mission_templates = {
	"build_bars": {
		"title": "Bar Empire",
		"description": "Build 3 bars to establish your drinking business",
		"type": "build",
		"target": 3,
		"building_type": "bar",
		"reward_money": 5000,
		"reward_heat_reduction": 10,
		"time_limit": 0
	},
	"survive_days": {
		"title": "Staying Alive",
		"description": "Survive 5 days without getting raided",
		"type": "survive",
		"target": 5,
		"current_days": 0,
		"reward_money": 8000,
		"reward_heat_reduction": 15,
		"time_limit": 10
	},
	"earn_money": {
		"title": "Money Maker",
		"description": "Accumulate $50,000 in dirty money",
		"type": "money",
		"target": 50000,
		"reward_money": 10000,
		"reward_heat_reduction": 5,
		"time_limit": 0
	},
	"low_heat": {
		"title": "Laying Low",
		"description": "Keep heat below 30% for 3 consecutive days",
		"type": "heat",
		"target": 30.0,
		"consecutive_days": 3,
		"current_days": 0,
		"reward_money": 7500,
		"reward_heat_reduction": 20,
		"time_limit": 7
	},
	"diversify": {
		"title": "Business Diversification",
		"description": "Own at least one of each building type",
		"type": "diversify",
		"required_types": ["bar", "club", "workshop", "ngo"],
		"reward_money": 15000,
		"reward_heat_reduction": 8,
		"time_limit": 0
	}
}

func _ready() -> void:
	# Connect to game events
	EventBus.building_placed.connect(_on_building_placed)
	TimeManager.day_changed.connect(_on_day_changed)
	
	# Start with initial missions
	generate_initial_missions()

func generate_initial_missions() -> void:
	# Start with 2-3 easy missions
	add_mission("build_bars")
	add_mission("earn_money")
	add_mission("low_heat")

func add_mission(template_key: String) -> Dictionary:
	if not mission_templates.has(template_key):
		print("Mission template not found: ", template_key)
		return {}
	
	var mission = mission_templates[template_key].duplicate(true)
	mission["id"] = generate_mission_id()
	mission["start_day"] = TimeManager.current_day
	mission["progress"] = 0
	mission["status"] = "active"
	
	active_missions.append(mission)
	new_mission_available.emit(mission)
	
	EventBus.notify("New Mission: " + mission["title"], "info")
	print("Mission added: ", mission["title"])
	
	return mission

func generate_mission_id() -> String:
	return "mission_" + str(Time.get_unix_time_from_system())

func update_mission_progress() -> void:
	for mission in active_missions:
		match mission["type"]:
			"build":
				update_build_mission(mission)
			"money":
				update_money_mission(mission)
			"heat":
				update_heat_mission(mission)
			"diversify":
				update_diversify_mission(mission)
		
		check_mission_completion(mission)
		check_mission_failure(mission)

func update_build_mission(mission: Dictionary) -> void:
	if mission["building_type"] == "any":
		mission["progress"] = count_total_buildings()
	else:
		mission["progress"] = count_buildings_of_type(mission["building_type"])

func update_money_mission(mission: Dictionary) -> void:
	mission["progress"] = int(Economy.dirty_money)

func update_heat_mission(mission: Dictionary) -> void:
	var current_heat = RiskSystem.get_current_heat()
	if current_heat <= mission["target"]:
		mission["current_days"] = mission.get("current_days", 0) + 1
		mission["progress"] = mission["current_days"]
	else:
		mission["current_days"] = 0
		mission["progress"] = 0

func update_diversify_mission(mission: Dictionary) -> void:
	var owned_types = get_owned_building_types()
	var required_types = mission["required_types"]
	var count = 0
	
	for type in required_types:
		if type in owned_types:
			count += 1
	
	mission["progress"] = count

func check_mission_completion(mission: Dictionary) -> void:
	var completed = false
	
	match mission["type"]:
		"build", "money", "diversify":
			completed = mission["progress"] >= mission["target"]
		"heat":
			completed = mission["current_days"] >= mission["consecutive_days"]
	
	if completed and mission["status"] == "active":
		complete_mission(mission)

func check_mission_failure(mission: Dictionary) -> void:
	if mission["time_limit"] > 0:
		var elapsed_days = TimeManager.current_day - mission["start_day"]
		if elapsed_days >= mission["time_limit"] and mission["status"] == "active":
			fail_mission(mission)

func complete_mission(mission: Dictionary) -> void:
	mission["status"] = "completed"
	active_missions.erase(mission)
	completed_missions.append(mission)
	
	# Give rewards
	Economy.add_dirty_money(mission["reward_money"])
	RiskSystem.reduce_heat(mission["reward_heat_reduction"])
	
	EventBus.notify_success("Mission Complete: " + mission["title"])
	EventBus.notify_success("Reward: $" + str(mission["reward_money"]) + " + Heat -" + str(mission["reward_heat_reduction"]))
	
	mission_completed.emit(mission)
	
	# Generate new mission
	generate_random_mission()

func fail_mission(mission: Dictionary) -> void:
	mission["status"] = "failed"
	active_missions.erase(mission)
	
	EventBus.notify_error("Mission Failed: " + mission["title"])
	mission_failed.emit(mission)
	
	# Small penalty
	RiskSystem.add_heat(5, "mission_failure")

func generate_random_mission() -> void:
	var template_keys = mission_templates.keys()
	var random_key = template_keys[randi() % template_keys.size()]
	
	# Don't duplicate active missions
	for active in active_missions:
		if active["title"] == mission_templates[random_key]["title"]:
			return
	
	add_mission(random_key)

func count_buildings_of_type(building_type: String) -> int:
	var count = 0
	var main_scene = get_tree().get_root().get_node("Main")
	if main_scene and main_scene.buildings_container:
		for building in main_scene.buildings_container.get_children():
			if building.has_meta("business_data"):
				var data = building.get_meta("business_data")
				if data.get("type") == building_type:
					count += 1
	return count

func count_total_buildings() -> int:
	var main_scene = get_tree().get_root().get_node("Main")
	if main_scene and main_scene.buildings_container:
		return main_scene.buildings_container.get_child_count()
	return 0

func get_owned_building_types() -> Array:
	var types = []
	var main_scene = get_tree().get_root().get_node("Main")
	if main_scene and main_scene.buildings_container:
		for building in main_scene.buildings_container.get_children():
			if building.has_meta("business_data"):
				var data = building.get_meta("business_data")
				var type = data.get("type")
				if type and type not in types:
					types.append(type)
	return types

func _on_building_placed(building_data: Dictionary) -> void:
	update_mission_progress()

func _on_day_changed(day: int) -> void:
	update_mission_progress()
	
	# Update survive missions
	for mission in active_missions:
		if mission["type"] == "survive":
			mission["current_days"] = mission.get("current_days", 0) + 1
			mission["progress"] = mission["current_days"]

func get_active_missions() -> Array[Dictionary]:
	return active_missions

func get_completed_missions() -> Array[Dictionary]:
	return completed_missions

func get_mission_progress_text(mission: Dictionary) -> String:
	match mission["type"]:
		"build":
			return str(mission["progress"]) + "/" + str(mission["target"]) + " " + mission["building_type"] + "s built"
		"money":
			return "$" + str(mission["progress"]) + "/$" + str(mission["target"])
		"heat":
			return str(mission["current_days"]) + "/" + str(mission["consecutive_days"]) + " days"
		"survive":
			return str(mission["current_days"]) + "/" + str(mission["target"]) + " days survived"
		"diversify":
			return str(mission["progress"]) + "/" + str(mission["required_types"].size()) + " types owned"
		_:
			return str(mission["progress"]) + "/" + str(mission["target"])