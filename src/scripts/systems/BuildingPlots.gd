extends Node2D
class_name BuildingPlots

signal plot_selected(plot_data: Dictionary)
signal plot_hovered(plot_data: Dictionary)

var plots: Array[Dictionary] = []
var plot_visuals: Array[Node2D] = []
var selected_plot: Dictionary = {}

const PLOT_SIZE = 64
const PLOTS_PER_DISTRICT = 12  # 3x4 grid per district

func _ready() -> void:
	generate_building_plots()
	# Enable processing for alternative input detection with higher priority
	set_process_unhandled_input(true)
	# Also enable regular input processing
	set_process_input(true)

func generate_building_plots() -> void:
	var districts_data = [
		{"id": 0, "name": "Downtown", "color": Color(0.3, 0.3, 0.5, 0.3)},
		{"id": 1, "name": "Industrial", "color": Color(0.4, 0.3, 0.2, 0.3)},
		{"id": 2, "name": "Residential", "color": Color(0.2, 0.4, 0.2, 0.3)},
		{"id": 3, "name": "Waterfront", "color": Color(0.2, 0.3, 0.4, 0.3)}
	]
	
	var _half_width = 50  # Half of map width in tiles
	var _half_height = 50  # Half of map height in tiles
	
	for district in districts_data:
		var district_id = district["id"]
		var district_plots = generate_district_plots(district_id, district["color"])
		plots.append_array(district_plots)

func generate_district_plots(district_id: int, color: Color) -> Array[Dictionary]:
	var district_plots: Array[Dictionary] = []
	var half_width = 50
	var half_height = 50
	
	# Calculate district bounds
	var start_x: int
	var start_y: int
	var end_x: int 
	var end_y: int
	
	match district_id:
		0:  # Top-left (Downtown)
			start_x = 5
			start_y = 5
			end_x = half_width - 5
			end_y = half_height - 5
		1:  # Top-right (Industrial)
			start_x = half_width + 5
			start_y = 5
			end_x = 100 - 5
			end_y = half_height - 5
		2:  # Bottom-left (Residential)
			start_x = 5
			start_y = half_height + 5
			end_x = half_width - 5
			end_y = 100 - 5
		3:  # Bottom-right (Waterfront)
			start_x = half_width + 5
			start_y = half_height + 5
			end_x = 100 - 5
			end_y = 100 - 5
	
	# Create a grid of plots in each district
	var plots_per_row = 4
	var plots_per_col = 3
	var spacing_x = float(end_x - start_x) / plots_per_row
	var spacing_y = float(end_y - start_y) / plots_per_col
	
	for row in range(plots_per_col):
		for col in range(plots_per_row):
			var plot_x = start_x + (col * spacing_x) + (spacing_x / 2.0)
			var plot_y = start_y + (row * spacing_y) + (spacing_y / 2.0)
			
			var plot_data = {
				"id": plots.size() + district_plots.size(),
				"district_id": district_id,
				"grid_pos": Vector2i(plot_x, plot_y),
				"world_pos": Vector2(plot_x * PLOT_SIZE, plot_y * PLOT_SIZE),
				"is_occupied": false,
				"building": null,
				"is_valid": true
			}
			
			district_plots.append(plot_data)
			create_plot_visual(plot_data, color)
	
	return district_plots

func create_plot_visual(plot_data: Dictionary, color: Color) -> void:
	var plot_visual = Node2D.new()
	plot_visual.name = "Plot_" + str(plot_data["id"])
	plot_visual.position = plot_data["world_pos"]
	
	# Main plot area
	var plot_rect = ColorRect.new()
	plot_rect.size = Vector2(PLOT_SIZE * 0.8, PLOT_SIZE * 0.8)
	plot_rect.position = -plot_rect.size / 2
	plot_rect.color = color
	plot_visual.add_child(plot_rect)
	
	# Border - create a simple outline
	var border = ColorRect.new()
	border.size = Vector2(PLOT_SIZE * 0.85, PLOT_SIZE * 0.85)
	border.position = -border.size / 2
	border.color = Color.TRANSPARENT
	
	# Create border lines manually
	for i in range(4):
		var line = ColorRect.new()
		line.color = Color.WHITE
		match i:
			0: # Top
				line.size = Vector2(border.size.x, 2)
				line.position = Vector2(0, 0)
			1: # Right
				line.size = Vector2(2, border.size.y)
				line.position = Vector2(border.size.x - 2, 0)
			2: # Bottom
				line.size = Vector2(border.size.x, 2)
				line.position = Vector2(0, border.size.y - 2)
			3: # Left
				line.size = Vector2(2, border.size.y)
				line.position = Vector2(0, 0)
		border.add_child(line)
	
	plot_visual.add_child(border)
	
	# Add interaction area with higher priority
	var area = Area2D.new()
	area.name = "PlotArea_" + str(plot_data["id"])
	area.priority = 10  # Higher priority than other areas
	area.monitorable = true
	area.monitoring = true
	# Enable input processing
	area.set_pickable(true)
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(PLOT_SIZE * 0.9, PLOT_SIZE * 0.9)  # Slightly smaller to avoid overlaps
	collision.shape = shape
	area.add_child(collision)
	plot_visual.add_child(area)
	
	# Store plot data in the visual
	plot_visual.set_meta("plot_data", plot_data)
	area.set_meta("plot_data", plot_data)
	
	# Connect signals with proper binding
	area.input_event.connect(_on_area_input_event.bind(plot_data))
	area.mouse_entered.connect(_on_plot_hovered.bind(plot_data))
	area.mouse_exited.connect(_on_plot_exited.bind(plot_data))
	
	# Ensure area is on correct collision layer (use layer 2 which is Buildings)
	area.collision_layer = 2  # Buildings layer (matches project settings)
	area.collision_mask = 0
	
	add_child(plot_visual)
	plot_visuals.append(plot_visual)


func _on_area_input_event(plot_data: Dictionary, _viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	print("Plot input event received: ", event, " for plot: ", plot_data["id"])
	if event.is_action_pressed("left_click"):
		print("Left click detected on plot: ", plot_data["id"])
		select_plot(plot_data)
		get_viewport().set_input_as_handled()  # Consume the event

func _on_plot_hovered(plot_data: Dictionary) -> void:
	print("Plot hovered: ", plot_data["id"])
	plot_hovered.emit(plot_data)
	highlight_plot(plot_data, Color.YELLOW)

func _on_plot_exited(plot_data: Dictionary) -> void:
	if selected_plot.get("id", -1) != plot_data["id"]:
		unhighlight_plot(plot_data)
	
	# Hide tooltip
	var main_scene = get_tree().get_root().get_node("Main")
	if main_scene and main_scene.plot_tooltip:
		main_scene.plot_tooltip.hide_tooltip()

func select_plot(plot_data: Dictionary) -> void:
	print("Selecting plot: ", plot_data["id"])
	
	# Clear previous selection
	if selected_plot.size() > 0:
		unhighlight_plot(selected_plot)
	
	selected_plot = plot_data
	highlight_plot(plot_data, Color.GREEN)
	
	print("Plot selected, emitting signal...")
	plot_selected.emit(plot_data)
	
	# Force immediate visual update
	var plot_visual = get_plot_visual(plot_data["id"])
	if plot_visual:
		print("Plot visual found and updating color")
		var rect = plot_visual.get_child(0) as ColorRect
		if rect:
			rect.modulate = Color.GREEN

func highlight_plot(plot_data: Dictionary, color: Color) -> void:
	var plot_visual = get_plot_visual(plot_data["id"])
	if plot_visual:
		var rect = plot_visual.get_child(0) as ColorRect
		if rect:
			rect.modulate = color

func unhighlight_plot(plot_data: Dictionary) -> void:
	var plot_visual = get_plot_visual(plot_data["id"])
	if plot_visual:
		var rect = plot_visual.get_child(0) as ColorRect
		if rect:
			rect.modulate = Color.WHITE

func get_plot_visual(plot_id: int) -> Node2D:
	for visual in plot_visuals:
		var data = visual.get_meta("plot_data", {})
		if data.get("id", -1) == plot_id:
			return visual
	return null

func occupy_plot(plot_id: int, building_data: Dictionary) -> bool:
	for i in range(plots.size()):
		if plots[i]["id"] == plot_id:
			if !plots[i]["is_occupied"]:
				plots[i]["is_occupied"] = true
				plots[i]["building"] = building_data
				
				# Update visual to show occupied
				var plot_visual = get_plot_visual(plot_id)
				if plot_visual:
					var rect = plot_visual.get_child(0) as ColorRect
					if rect:
						rect.modulate = Color.GRAY
				return true
	return false

func get_available_plots() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for plot in plots:
		if !plot["is_occupied"]:
			available.append(plot)
	return available

func get_plots_in_district(district_id: int) -> Array[Dictionary]:
	var district_plots: Array[Dictionary] = []
	for plot in plots:
		if plot["district_id"] == district_id:
			district_plots.append(plot)
	return district_plots

func is_plot_valid_for_building(plot_data: Dictionary, building_type: String) -> bool:
	if plot_data["is_occupied"]:
		return false
	
	# Add specific building restrictions per district
	var district_id = plot_data["district_id"]
	match building_type:
		"workshop":
			# Workshops preferred in industrial district
			return district_id == 1 or district_id == 2
		"club":
			# Clubs work better in downtown and waterfront
			return district_id == 0 or district_id == 3
		"ngo":
			# NGOs can be anywhere but industrial
			return district_id != 1
		_:
			return true

func _input(event: InputEvent) -> void:
	# Only handle input if we're in building mode or the click is over a plot
	if event.is_action_pressed("left_click"):
		var main_scene = get_tree().get_root().get_node_or_null("Main")
		if main_scene and main_scene.is_placing_building:
			print("Input left click detected during building mode at: ", event.position)
			var handled = check_plot_click_at_position_immediate(event.position)
			if handled:
				get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		print("Unhandled left click detected at: ", event.position)  
		check_plot_click_at_position(event.position)

func check_plot_click_at_position(_screen_pos: Vector2) -> void:
	# Convert screen position to world position
	var world_pos = get_global_mouse_position()
	print("Checking for plot at world position: ", world_pos)
	
	# Find closest plot
	var closest_plot = find_plot_at_position(world_pos)
	if closest_plot.size() > 0:
		print("Found plot at position: ", closest_plot["id"])
		select_plot(closest_plot)
		get_viewport().set_input_as_handled()

func check_plot_click_at_position_immediate(_screen_pos: Vector2) -> bool:
	# Convert screen position to world position
	var world_pos = get_global_mouse_position()
	print("Immediate click check at world position: ", world_pos)
	
	# Find closest plot
	var closest_plot = find_plot_at_position(world_pos)
	if closest_plot.size() > 0:
		print("Found plot at position (immediate): ", closest_plot["id"])
		select_plot(closest_plot)
		return true
	return false

func find_plot_at_position(world_pos: Vector2) -> Dictionary:
	var min_distance = 999999.0
	var closest_plot = {}
	
	for plot in plots:
		var plot_world_pos = plot.get("world_pos", Vector2.ZERO)
		var distance = world_pos.distance_to(plot_world_pos)
		if distance < min_distance and distance < PLOT_SIZE:
			min_distance = distance
			closest_plot = plot
	
	return closest_plot
