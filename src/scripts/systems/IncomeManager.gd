extends Node
class_name IncomeManager

signal income_cycle_completed(total_income: float)

var income_cycle_time: float = 5.0  # Generate income every 5 seconds for better feedback
var income_timer: Timer

func _ready() -> void:
	setup_income_timer()
	print("IncomeManager initialized")

func setup_income_timer() -> void:
	income_timer = Timer.new()
	income_timer.wait_time = income_cycle_time
	income_timer.timeout.connect(_on_income_cycle)
	income_timer.autostart = true
	add_child(income_timer)

func _on_income_cycle() -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	var total_income = 0.0
	var businesses = ShadowOps.get_active_businesses()
	var is_night = !GameManager.is_day
	
	for business in businesses:
		var income = calculate_business_income(business, is_night)
		total_income += income
		
		# Find building node to show visual effect
		var building_node = find_building_node(business)
		if building_node:
			building_node.generate_income(income)
	
	if total_income > 0:
		Economy.add_dirty_money(total_income)
		EventBus.notify_money_gain(total_income, "business operations")
		income_cycle_completed.emit(total_income)
		
		# Add heat based on income generated
		RiskSystem.add_heat(total_income / 5000.0, "business_operation")

func calculate_business_income(business: Dictionary, is_night: bool) -> float:
	var district_info = CitySim.get_district_info(business["district_id"])
	var district_demand = district_info.get("demand", 1.0)
	var local_heat = district_info.get("heat", 0.0) / 100.0
	
	return Economy.calculate_business_income(
		business["data"]["base_income"],
		district_demand,
		local_heat,
		is_night,
		business["type"]
	)

func find_building_node(business: Dictionary) -> Node2D:
	var main_scene = get_tree().get_root().get_node("Main")
	if !main_scene:
		return null
	
	var buildings_container = main_scene.get_node("World/Buildings")
	if !buildings_container:
		return null
	
	for building in buildings_container.get_children():
		if building.has_method("business_data") or building.business_data.get("id", -1) == business["id"]:
			return building
	
	return null

func set_income_cycle_time(new_time: float) -> void:
	income_cycle_time = new_time
	if income_timer:
		income_timer.wait_time = income_cycle_time

func pause_income() -> void:
	if income_timer:
		income_timer.paused = true

func resume_income() -> void:
	if income_timer:
		income_timer.paused = false