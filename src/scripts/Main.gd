extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var tile_map: TileMapLayer = $World/TileMapLayer
@onready var buildings_container: Node2D = $World/Buildings
@onready var districts_container: Node2D = $World/Districts

var camera_speed: float = 500.0
var zoom_speed: float = 0.1
var min_zoom: float = 0.3
var max_zoom: float = 2.0

var grid_size: int = 64
var map_width: int = 100
var map_height: int = 100

var current_tool: String = ""
var selected_building_type: String = ""
var is_placing_building: bool = false

var grid_overlay: Node2D
var building_preview: Node2D
var show_grid: bool = true
var income_manager: IncomeManager
var effects_manager: EffectsManager
var building_plots: BuildingPlots
var selected_plot_data: Dictionary = {}
var plot_tooltip: PlotTooltip
var enhanced_grid: EnhancedGrid
var construction_manager: ConstructionManager
var notification_history: NotificationHistory
var notification_panel: NotificationPanel
var mission_system: MissionSystem
var save_load_panel: SaveLoadPanel

func _ready() -> void:
	initialize_map()
	setup_camera()
	setup_income_manager()
	connect_signals()
	GameManager.start_game()
	show_initial_help()
	print("Main scene initialized")

func initialize_map() -> void:
	# Generate district visuals
	MapGenerator.generate_district_visuals(districts_container)
	
	# Generate roads
	MapGenerator.generate_roads($World)
	
	# Setup enhanced grid system (initially hidden to avoid conflicts)
	enhanced_grid = EnhancedGrid.new()
	enhanced_grid.name = "EnhancedGrid"
	enhanced_grid.grid_size = grid_size
	enhanced_grid.map_width = map_width
	enhanced_grid.map_height = map_height
	enhanced_grid.visible = false
	$World.add_child(enhanced_grid)
	
	# Setup building plots system
	building_plots = BuildingPlots.new()
	building_plots.name = "BuildingPlots"
	$World.add_child(building_plots)
	
	print("Map initialized: ", map_width, "x", map_height)

func setup_camera() -> void:
	camera.position = Vector2(map_width * grid_size / 2, map_height * grid_size / 2)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_width * grid_size
	camera.limit_bottom = map_height * grid_size

func setup_income_manager() -> void:
	income_manager = IncomeManager.new()
	add_child(income_manager)
	income_manager.income_cycle_completed.connect(_on_income_cycle_completed)
	
	# Setup effects manager
	effects_manager = EffectsManager.new()
	add_child(effects_manager)
	
	# Setup notification history
	notification_history = NotificationHistory.new()
	notification_history.add_to_group("notification_history")
	add_child(notification_history)
	
	# Setup construction manager
	construction_manager = ConstructionManager.new()
	construction_manager.enhanced_grid = enhanced_grid
	construction_manager.building_plots = building_plots
	construction_manager.effects_manager = effects_manager
	$World.add_child(construction_manager)
	
	# Setup plot tooltip
	plot_tooltip = PlotTooltip.new()
	$UI.add_child(plot_tooltip)
	
	# Setup notification panel
	notification_panel = NotificationPanel.new()
	$UI.add_child(notification_panel)
	
	# Setup mission system
	mission_system = MissionSystem.new()
	add_child(mission_system)
	
	# Setup save/load system
	save_load_panel = SaveLoadPanel.new()
	$UI.add_child(save_load_panel)

func connect_signals() -> void:
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.district_clicked.connect(_on_district_clicked)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	TimeManager.cycle_changed.connect(_on_cycle_changed)
	
	# Connect building plots signals
	if building_plots:
		building_plots.plot_selected.connect(_on_plot_selected)
		building_plots.plot_hovered.connect(_on_plot_hovered)

func _process(delta: float) -> void:
	handle_camera_movement(delta)
	if is_placing_building:
		update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		zoom_camera(zoom_speed)
	elif event.is_action_pressed("zoom_out"):
		zoom_camera(-zoom_speed)
	elif event.is_action_pressed("right_click"):
		cancel_building_placement()
	
	# New shortcuts
	elif event is InputEventKey:
		match event.keycode:
			KEY_H:
				if event.pressed:
					toggle_notification_history()
			KEY_G:
				if event.pressed:
					toggle_enhanced_grid()
			KEY_ESCAPE:
				if event.pressed and is_placing_building:
					cancel_building_placement()
			KEY_F5:
				if event.pressed:
					quick_save()
			KEY_F9:
				if event.pressed:
					show_load_menu()
			KEY_S:
				if event.pressed and event.ctrl_pressed:
					show_save_menu()
	
	# Don't handle left clicks in _unhandled_input - let building plots handle them
	# This prevents Main from intercepting clicks before they reach the Area2D nodes

func handle_camera_movement(delta: float) -> void:
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	
	if direction != Vector2.ZERO:
		camera.position += direction.normalized() * camera_speed * delta

func zoom_camera(zoom_delta: float) -> void:
	var new_zoom = camera.zoom + Vector2(zoom_delta, zoom_delta)
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	camera.zoom = new_zoom

func handle_left_click() -> void:
	if is_placing_building:
		place_building()
	else:
		check_building_selection()

func start_building_placement(building_type: String) -> void:
	if ShadowOps.can_build_business(building_type, Economy.dirty_money):
		selected_building_type = building_type
		is_placing_building = true
		current_tool = "build"
		
		# Use enhanced construction system
		if construction_manager:
			construction_manager.start_construction_mode(building_type)
		else:
			# Fallback to old system
			highlight_valid_plots(building_type)
			EventBus.notify("Select a plot to build " + building_type + ". Right-click to cancel.")
	else:
		EventBus.notify_error("Not enough dirty money to build " + building_type)

func place_building() -> void:
	# This is now handled by plot selection
	if selected_plot_data.size() > 0 and is_placing_building:
		build_on_selected_plot()

func build_on_selected_plot() -> void:
	if !building_plots.is_plot_valid_for_building(selected_plot_data, selected_building_type):
		EventBus.notify_error("Cannot build " + selected_building_type + " on this plot!")
		return
	
	var cost = ShadowOps.business_types[selected_building_type]["cost"]
	if Economy.spend_dirty_money(cost):
		var business = ShadowOps.build_business(
			selected_building_type, 
			selected_plot_data["district_id"], 
			selected_plot_data["world_pos"]
		)
		
		if business.size() > 0:
			# Occupy the plot
			building_plots.occupy_plot(selected_plot_data["id"], business)
			
			# Create building visual
			create_building_visual(business)
			CitySim.add_business_to_district(selected_plot_data["district_id"], business)
			
			EventBus.notify_success(selected_building_type.capitalize() + " built!")
			EventBus.building_placed.emit(business)
			
		cancel_building_placement()
	else:
		EventBus.notify_error("Not enough dirty money!")

func cancel_building_placement() -> void:
	is_placing_building = false
	selected_building_type = ""
	current_tool = ""
	selected_plot_data = {}
	
	# Use enhanced construction system
	if construction_manager:
		construction_manager.end_construction_mode()
	else:
		# Fallback to old system
		if building_plots:
			clear_plot_highlights()
	
	if building_preview:
		building_preview.queue_free()
		building_preview = null

func create_building_visual(business: Dictionary) -> void:
	var building_scene = preload("res://src/scripts/buildings/Building.gd")
	var building_node = Node2D.new()
	building_node.set_script(building_scene)
	building_node.position = business["position"]
	building_node.business_data = business
	building_node.clicked.connect(_on_building_clicked)
	building_node.income_generated.connect(_on_building_income_generated)
	buildings_container.add_child(building_node)

func update_building_preview() -> void:
	if !building_preview:
		create_building_preview()
	
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	var world_pos = grid_to_world(grid_pos)
	
	building_preview.position = world_pos
	
	# Update preview color based on validity
	if is_valid_building_position(grid_pos):
		building_preview.modulate = Color(0, 1, 0, 0.5)  # Green = valid
	else:
		building_preview.modulate = Color(1, 0, 0, 0.5)  # Red = invalid

func create_building_preview() -> void:
	building_preview = Node2D.new()
	
	# Create preview visual
	var preview_rect = ColorRect.new()
	preview_rect.size = Vector2(grid_size * 0.8, grid_size * 0.8)
	preview_rect.position = -preview_rect.size / 2
	
	match selected_building_type:
		"bar":
			preview_rect.color = Color(0.6, 0.4, 0.2)
		"club":
			preview_rect.color = Color(0.5, 0.2, 0.5)
		"workshop":
			preview_rect.color = Color(0.3, 0.3, 0.3)
		"ngo":
			preview_rect.color = Color(0.3, 0.5, 0.7)
		"casino":
			preview_rect.color = Color(0.8, 0.2, 0.2)
		"pawnshop":
			preview_rect.color = Color(0.7, 0.6, 0.3)
		"restaurant":
			preview_rect.color = Color(0.4, 0.6, 0.3)
		"garage":
			preview_rect.color = Color(0.4, 0.4, 0.4)
		_:
			preview_rect.color = Color.WHITE
	
	building_preview.add_child(preview_rect)
	add_child(building_preview)

func is_valid_building_position(grid_pos: Vector2i) -> bool:
	# Check if position is within map bounds
	if grid_pos.x < 0 or grid_pos.x >= map_width:
		return false
	if grid_pos.y < 0 or grid_pos.y >= map_height:
		return false
	
	# Check if position is not on a road
	var half_width = map_width / 2
	var half_height = map_height / 2
	if abs(grid_pos.x - half_width) < 1 or abs(grid_pos.y - half_height) < 1:
		return false
	
	# Check if position is not occupied by another building
	var world_pos = grid_to_world(grid_pos)
	for building in buildings_container.get_children():
		if building.position.distance_to(world_pos) < grid_size:
			return false
	
	return true

func check_building_selection() -> void:
	var mouse_pos = get_global_mouse_position()
	for building in buildings_container.get_children():
		if building.get_global_rect().has_point(mouse_pos):
			var business_data = building.get_meta("business_data", {})
			if business_data.size() > 0:
				EventBus.building_selected.emit(business_data)
				return

func get_district_at_position(grid_pos: Vector2i) -> int:
	# Simple district division: map divided into 4 quadrants
	var half_width = map_width / 2
	var half_height = map_height / 2
	
	if grid_pos.x < half_width:
		if grid_pos.y < half_height:
			return 0  # Top-left
		else:
			return 2  # Bottom-left
	else:
		if grid_pos.y < half_height:
			return 1  # Top-right
		else:
			return 3  # Bottom-right

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / grid_size), int(world_pos.y / grid_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * grid_size + grid_size / 2, grid_pos.y * grid_size + grid_size / 2)

func _on_building_selected(building: Dictionary) -> void:
	print("Building selected: ", building["type"], " at ", building["position"])

func _on_building_clicked(building: Node2D) -> void:
	if building.has_meta("business_data"):
		var data = building.get_meta("business_data")
		EventBus.building_selected.emit(data)

func _on_building_income_generated(amount: float) -> void:
	Economy.add_dirty_money(amount)
	RiskSystem.add_heat(amount / 1000.0, "business_operation")

func _on_income_cycle_completed(total_income: float) -> void:
	print("Income cycle completed: +$", total_income)
	if effects_manager and total_income > 0:
		# Create floating text at a central location
		var center = Vector2(map_width * grid_size / 2, 100)
		effects_manager.create_floating_text(center, total_income, true)

func _on_district_clicked(district_id: int) -> void:
	print("District clicked: ", district_id)

func _on_game_paused(is_paused: bool) -> void:
	set_process(!is_paused)
	if income_manager:
		if is_paused:
			income_manager.pause_income()
		else:
			income_manager.resume_income()

func _on_day_night_changed(is_day: bool) -> void:
	# Visual feedback for day/night cycle
	var tween = create_tween()
	if is_day:
		tween.tween_property(camera, "modulate", Color.WHITE, 2.0)
		EventBus.notify("Dawn breaks over the city", "info")
	else:
		tween.tween_property(camera, "modulate", Color(0.7, 0.7, 1.0), 2.0)
		EventBus.notify("Night falls - clubs are more profitable!", "info")

func _on_cycle_changed(is_day: bool) -> void:
	# Update building visuals based on day/night
	for building in buildings_container.get_children():
		if building.has_method("on_cycle_changed"):
			building.on_cycle_changed(is_day)

func _on_plot_selected(plot_data: Dictionary) -> void:
	selected_plot_data = plot_data
	print("Plot selected in district: ", plot_data["district_id"])
	
	if is_placing_building:
		# Try to build on selected plot
		build_on_selected_plot()

func _on_plot_hovered(plot_data: Dictionary) -> void:
	if plot_tooltip:
		plot_tooltip.show_plot_info(plot_data, selected_building_type)
		plot_tooltip.update_position(get_global_mouse_position())

func highlight_valid_plots(building_type: String) -> void:
	if !building_plots:
		return
	
	var available_plots = building_plots.get_available_plots()
	for plot in available_plots:
		if building_plots.is_plot_valid_for_building(plot, building_type):
			building_plots.highlight_plot(plot, Color.GREEN)
		else:
			building_plots.highlight_plot(plot, Color.RED)

func clear_plot_highlights() -> void:
	if !building_plots:
		return
	
	var all_plots = building_plots.plots
	for plot in all_plots:
		if !plot["is_occupied"]:
			building_plots.unhighlight_plot(plot)

func get_district_name(district_id: int) -> String:
	match district_id:
		0: return "Downtown"
		1: return "Industrial"
		2: return "Residential"
		3: return "Waterfront"
		_: return "Unknown"

func toggle_notification_history() -> void:
	if notification_panel:
		if notification_panel.visible:
			notification_panel.hide_panel()
		else:
			notification_panel.show_panel()

func toggle_enhanced_grid() -> void:
	if enhanced_grid:
		enhanced_grid.toggle_grid()
		EventBus.notify("Grid " + ("shown" if enhanced_grid.is_visible else "hidden"), "info")

func show_initial_help() -> void:
	EventBus.notify("Welcome to Underworld Tycoon!", "success")
	EventBus.notify("Use Tab to switch between Legal/Illegal panels", "info")
	EventBus.notify("Click on colored squares to build businesses", "info")
	EventBus.notify("Press H to view notification history", "info")
	EventBus.notify("Press G to toggle grid overlay", "info")
	EventBus.notify("Press F5 to quick save, F9 to load, Ctrl+S to save menu", "info")

func quick_save() -> void:
	if save_load_panel and save_load_panel.save_system:
		var success = save_load_panel.save_system.save_game(1, "Quick Save")
		if success:
			EventBus.notify_success("Quick save completed")
		else:
			EventBus.notify_error("Quick save failed")

func show_save_menu() -> void:
	if save_load_panel:
		save_load_panel.show_save_panel()

func show_load_menu() -> void:
	if save_load_panel:
		save_load_panel.show_load_panel()
