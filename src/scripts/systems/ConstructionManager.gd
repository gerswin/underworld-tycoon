extends Node2D
class_name ConstructionManager

signal construction_started(building_data: Dictionary)
signal construction_completed(building_data: Dictionary)
signal construction_cancelled()

var enhanced_grid: EnhancedGrid
var building_plots: BuildingPlots
var effects_manager: EffectsManager

var is_construction_mode: bool = false
var selected_building_type: String = ""
var construction_queue: Array[Dictionary] = []

var construction_ui: Control
var ghost_buildings: Array[Node2D] = []

func _ready() -> void:
	setup_construction_ui()
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup_construction_ui() -> void:
	construction_ui = Control.new()
	construction_ui.name = "ConstructionUI"
	construction_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(construction_ui)
	
	# Create construction info panel
	create_info_panel()

func create_info_panel() -> void:
	var info_panel = ColorRect.new()
	info_panel.color = Color(0.1, 0.1, 0.1, 0.8)
	info_panel.size = Vector2(250, 100)
	info_panel.position = Vector2(20, 20)
	info_panel.visible = false
	construction_ui.add_child(info_panel)
	
	var info_label = Label.new()
	info_label.position = Vector2(10, 10)
	info_label.size = Vector2(230, 80)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.name = "InfoLabel"
	info_panel.add_child(info_label)
	
	info_panel.name = "InfoPanel"

func start_construction_mode(building_type: String) -> void:
	is_construction_mode = true
	selected_building_type = building_type
	
	# Show construction info
	show_construction_info(building_type)
	
	# Enable enhanced grid if available
	if enhanced_grid:
		enhanced_grid.show_grid()
		enhanced_grid.grid_cell_hovered.connect(_on_grid_cell_hovered)
		enhanced_grid.grid_cell_clicked.connect(_on_grid_cell_clicked)
	
	# Highlight valid plots if available
	if building_plots:
		highlight_valid_plots(building_type)
	
	print("Construction mode started for: ", building_type)

func end_construction_mode() -> void:
	is_construction_mode = false
	selected_building_type = ""
	
	# Hide construction UI
	hide_construction_info()
	
	# Disable enhanced grid
	if enhanced_grid:
		enhanced_grid.hide_grid()
		if enhanced_grid.grid_cell_hovered.is_connected(_on_grid_cell_hovered):
			enhanced_grid.grid_cell_hovered.disconnect(_on_grid_cell_hovered)
		if enhanced_grid.grid_cell_clicked.is_connected(_on_grid_cell_clicked):
			enhanced_grid.grid_cell_clicked.disconnect(_on_grid_cell_clicked)
	
	# Clear plot highlights
	if building_plots:
		clear_plot_highlights()
	
	# Clear ghost buildings
	clear_ghost_buildings()
	
	construction_cancelled.emit()
	print("Construction mode ended")

func show_construction_info(building_type: String) -> void:
	var info_panel = construction_ui.get_node_or_null("InfoPanel")
	var info_label = construction_ui.get_node_or_null("InfoPanel/InfoLabel")
	
	if info_panel and info_label:
		var building_data = ShadowOps.business_types.get(building_type, {})
		var cost = building_data.get("cost", 0)
		var income = building_data.get("base_income", 0)
		var heat = building_data.get("heat_generation", 0)
		
		var info_text = "Building: %s\nCost: $%s\nIncome: $%s/cycle\nHeat: +%s\n\nClick on highlighted plots to build\nRight-click to cancel" % [
			building_type.capitalize(),
			format_money(cost),
			format_money(income),
			str(heat)
		]
		
		info_label.text = info_text
		info_panel.visible = true
		
		# Animate panel appearance
		info_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(info_panel, "modulate:a", 1.0, 0.3)

func hide_construction_info() -> void:
	var info_panel = construction_ui.get_node_or_null("InfoPanel")
	if info_panel:
		var tween = create_tween()
		tween.tween_property(info_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): info_panel.visible = false)

func _on_grid_cell_hovered(grid_pos: Vector2i) -> void:
	if !is_construction_mode:
		return
	
	# Update grid preview
	if enhanced_grid:
		var is_valid = is_valid_construction_position(grid_pos)
		enhanced_grid.show_construction_preview(grid_pos, selected_building_type, is_valid)
	
	# Show ghost building
	show_ghost_building(grid_pos)

func _on_grid_cell_clicked(grid_pos: Vector2i) -> void:
	if !is_construction_mode:
		return
	
	if is_valid_construction_position(grid_pos):
		attempt_construction(grid_pos)
	else:
		show_construction_error(grid_pos)

func show_ghost_building(grid_pos: Vector2i) -> void:
	clear_ghost_buildings()
	
	if !enhanced_grid:
		return
	
	var world_pos = enhanced_grid.grid_to_world(grid_pos)
	var ghost = create_ghost_building(selected_building_type, is_valid_construction_position(grid_pos))
	ghost.position = world_pos
	ghost.modulate.a = 0.6
	
	add_child(ghost)
	ghost_buildings.append(ghost)

func create_ghost_building(building_type: String, is_valid: bool) -> Node2D:
	var ghost = Node2D.new()
	
	# Main building visual
	var rect = ColorRect.new()
	rect.size = Vector2(60, 60)
	rect.position = -rect.size / 2
	
	match building_type:
		"bar":
			rect.color = Color(0.6, 0.4, 0.2)
		"club":
			rect.color = Color(0.5, 0.2, 0.5)
		"workshop":
			rect.color = Color(0.3, 0.3, 0.3)
		"ngo":
			rect.color = Color(0.3, 0.5, 0.7)
		_:
			rect.color = Color.WHITE
	
	if !is_valid:
		rect.color = Color.RED
	
	ghost.add_child(rect)
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(ghost, "modulate:a", 0.3, 0.5)
	tween.tween_property(ghost, "modulate:a", 0.8, 0.5)
	
	return ghost

func clear_ghost_buildings() -> void:
	for ghost in ghost_buildings:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ghost_buildings.clear()

func is_valid_construction_position(grid_pos: Vector2i) -> bool:
	# Check if within bounds
	if !enhanced_grid or !enhanced_grid.is_grid_position_valid(grid_pos):
		return false
	
	# Check if plot system allows construction
	if building_plots:
		# Find corresponding plot
		var world_pos = enhanced_grid.grid_to_world(grid_pos)
		var plot_data = find_plot_at_position(world_pos)
		if plot_data.size() > 0:
			return building_plots.is_plot_valid_for_building(plot_data, selected_building_type)
	
	return true

func find_plot_at_position(world_pos: Vector2) -> Dictionary:
	if !building_plots:
		return {}
	
	# Find the closest plot to the world position
	var min_distance = 999999.0
	var closest_plot = {}
	
	for plot in building_plots.plots:
		var plot_pos = plot.get("world_pos", Vector2.ZERO)
		var distance = world_pos.distance_to(plot_pos)
		if distance < min_distance and distance < 64:  # Within one grid cell
			min_distance = distance
			closest_plot = plot
	
	return closest_plot

func attempt_construction(grid_pos: Vector2i) -> void:
	var world_pos = enhanced_grid.grid_to_world(grid_pos) if enhanced_grid else Vector2.ZERO
	var plot_data = find_plot_at_position(world_pos)
	
	if plot_data.size() == 0:
		show_error_message("No valid plot found at this position")
		return
	
	# Check if can afford
	var cost = ShadowOps.business_types[selected_building_type]["cost"]
	if !Economy.spend_dirty_money(cost):
		show_error_message("Not enough dirty money!")
		return
	
	# Create building
	var business = ShadowOps.build_business(
		selected_building_type,
		plot_data["district_id"],
		plot_data["world_pos"]
	)
	
	if business.size() > 0:
		# Mark plot as occupied
		if building_plots:
			building_plots.occupy_plot(plot_data["id"], business)
		
		# Show construction effects
		if effects_manager:
			effects_manager.create_building_effect(world_pos, "construction_complete")
		
		construction_started.emit(business)
		EventBus.notify_success(selected_building_type.capitalize() + " construction started!")
		
		# End construction mode
		end_construction_mode()
	else:
		show_error_message("Failed to create building")
		# Refund money
		Economy.add_dirty_money(cost)

func show_construction_error(grid_pos: Vector2i) -> void:
	var world_pos = enhanced_grid.grid_to_world(grid_pos) if enhanced_grid else Vector2.ZERO
	
	if effects_manager:
		effects_manager.create_floating_message(world_pos, "Cannot build here!", Color.RED)
	
	show_error_message("Invalid construction location")

func show_error_message(message: String) -> void:
	EventBus.notify_error(message)

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
	
	for plot in building_plots.plots:
		if !plot["is_occupied"]:
			building_plots.unhighlight_plot(plot)

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return str(snapped(amount / 1000000.0, 0.1)) + "M"
	elif amount >= 1000:
		return str(snapped(amount / 1000.0, 0.1)) + "K"
	else:
		return str(int(amount))

func _unhandled_input(event: InputEvent) -> void:
	if is_construction_mode and event.is_action_pressed("right_click"):
		end_construction_mode()