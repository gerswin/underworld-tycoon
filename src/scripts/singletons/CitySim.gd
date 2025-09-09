extends Node

signal approval_changed(new_approval: float)
signal service_quality_changed(service: String, quality: float)
signal district_updated(district_id: int)

var city_approval: float = 60.0
var districts: Array[Dictionary] = []

var public_services: Dictionary = {
	"garbage": {"quality": 50.0, "cost": 1000.0, "importance": 0.2},
	"transport": {"quality": 50.0, "cost": 1500.0, "importance": 0.3},
	"police": {"quality": 50.0, "cost": 2000.0, "importance": 0.3},
	"public_works": {"quality": 50.0, "cost": 2500.0, "importance": 0.2}
}

func _ready() -> void:
	initialize_districts()
	print("CitySim initialized with ", districts.size(), " districts")

func initialize_districts() -> void:
	for i in range(4):
		districts.append({
			"id": i,
			"name": "District " + str(i + 1),
			"population": randi_range(10000, 50000),
			"demand": randf_range(0.5, 1.5),
			"heat": 0.0,
			"businesses": [],
			"prosperity": 50.0
		})

func update_service_quality(service: String, investment: float) -> void:
	if service in public_services:
		var max_quality = 100.0
		var efficiency = investment / public_services[service]["cost"]
		public_services[service]["quality"] = min(efficiency * 100.0, max_quality)
		service_quality_changed.emit(service, public_services[service]["quality"])
		calculate_approval()

func calculate_approval() -> void:
	var total_quality = 0.0
	var total_importance = 0.0
	
	for service in public_services:
		var quality = public_services[service]["quality"]
		var importance = public_services[service]["importance"]
		total_quality += quality * importance
		total_importance += importance
	
	var service_approval = total_quality / total_importance if total_importance > 0 else 50.0
	
	var average_heat = get_average_heat()
	var heat_penalty = average_heat * 0.5
	
	var prosperity_bonus = get_average_prosperity() * 0.2
	
	city_approval = clamp(service_approval - heat_penalty + prosperity_bonus, 0.0, 100.0)
	approval_changed.emit(city_approval)

func get_average_heat() -> float:
	if districts.is_empty():
		return 0.0
	var total = 0.0
	for district in districts:
		total += district["heat"]
	return total / districts.size()

func get_average_prosperity() -> float:
	if districts.is_empty():
		return 50.0
	var total = 0.0
	for district in districts:
		total += district["prosperity"]
	return total / districts.size()

func add_business_to_district(district_id: int, business_data: Dictionary) -> void:
	if district_id >= 0 and district_id < districts.size():
		districts[district_id]["businesses"].append(business_data)
		districts[district_id]["heat"] += business_data.get("heat_generation", 0.0)
		district_updated.emit(district_id)

func get_district_info(district_id: int) -> Dictionary:
	if district_id >= 0 and district_id < districts.size():
		return districts[district_id]
	return {}

func update_district_heat(district_id: int, heat_change: float) -> void:
	if district_id >= 0 and district_id < districts.size():
		districts[district_id]["heat"] = clamp(districts[district_id]["heat"] + heat_change, 0.0, 100.0)
		district_updated.emit(district_id)
		calculate_approval()

func get_total_service_cost() -> float:
	var total = 0.0
	for service in public_services:
		total += public_services[service]["cost"]
	return total

func apply_scandal(severity: float) -> void:
	city_approval = max(0.0, city_approval - severity * 10.0)
	approval_changed.emit(city_approval)

func get_save_data() -> Dictionary:
	return {
		"city_approval": city_approval,
		"districts": districts,
		"public_services": public_services
	}

func load_save_data(data: Dictionary) -> void:
	city_approval = data.get("city_approval", 60.0)
	districts = data.get("districts", [])
	public_services = data.get("public_services", public_services)
	approval_changed.emit(city_approval)