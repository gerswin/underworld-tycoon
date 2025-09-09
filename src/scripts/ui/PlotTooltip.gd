extends Control
class_name PlotTooltip

var background: ColorRect
var title_label: Label
var info_label: Label
var stats_container: VBoxContainer

var is_visible_tooltip: bool = false
var fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	setup_tooltip()

func setup_tooltip() -> void:
	# Background - use ColorRect instead of NinePatchRect
	background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.9)
	background.size = Vector2(250, 120)
	add_child(background)
	
	# Title
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", Color.YELLOW)
	title_label.position = Vector2(10, 5)
	title_label.text = "Plot Information"
	add_child(title_label)
	
	# Info container
	stats_container = VBoxContainer.new()
	stats_container.position = Vector2(10, 25)
	stats_container.size = Vector2(230, 90)
	add_child(stats_container)

func show_plot_info(plot_data: Dictionary, building_type: String = "") -> void:
	# Clear previous info
	for child in stats_container.get_children():
		child.queue_free()
	
	var district_name = get_district_name(plot_data["district_id"])
	title_label.text = district_name + " - Plot " + str(plot_data["id"])
	
	# District info
	add_info_line("District", district_name)
	
	# Status
	var status = "Available" if !plot_data["is_occupied"] else "Occupied"
	var status_color = Color.GREEN if !plot_data["is_occupied"] else Color.RED
	add_info_line("Status", status, status_color)
	
	# If building type is selected, show compatibility
	if building_type != "":
		var is_valid = is_plot_valid_for_building(plot_data, building_type)
		var validity_text = "Compatible" if is_valid else "Not suitable"
		var validity_color = Color.GREEN if is_valid else Color.RED
		add_info_line("For " + building_type.capitalize(), validity_text, validity_color)
		
		# Show why it's not suitable
		if !is_valid and !plot_data["is_occupied"]:
			add_info_line("Reason", get_incompatibility_reason(plot_data, building_type), Color.ORANGE)
	
	# District bonuses
	var bonuses = get_district_bonuses(plot_data["district_id"])
	if bonuses != "":
		add_info_line("District Bonus", bonuses, Color.CYAN)
	
	show_tooltip()

func add_info_line(label: String, value: String, color: Color = Color.WHITE) -> void:
	var line_container = HBoxContainer.new()
	
	var label_node = Label.new()
	label_node.text = label + ": "
	label_node.add_theme_font_size_override("font_size", 12)
	label_node.custom_minimum_size.x = 80
	line_container.add_child(label_node)
	
	var value_node = Label.new()
	value_node.text = value
	value_node.add_theme_font_size_override("font_size", 12)
	value_node.add_theme_color_override("font_color", color)
	line_container.add_child(value_node)
	
	stats_container.add_child(line_container)

func show_tooltip() -> void:
	if fade_tween:
		fade_tween.kill()
	
	is_visible_tooltip = true
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_tooltip() -> void:
	if fade_tween:
		fade_tween.kill()
	
	is_visible_tooltip = false
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)

func update_position(mouse_pos: Vector2) -> void:
	var screen_size = get_viewport().get_visible_rect().size
	var tooltip_size = background.size
	
	# Position tooltip to avoid screen edges
	var pos = mouse_pos + Vector2(10, -tooltip_size.y - 10)
	
	if pos.x + tooltip_size.x > screen_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - 10
	if pos.y < 0:
		pos.y = mouse_pos.y + 10
	
	position = pos

func get_district_name(district_id: int) -> String:
	match district_id:
		0: return "Downtown"
		1: return "Industrial"
		2: return "Residential" 
		3: return "Waterfront"
		_: return "Unknown"

func is_plot_valid_for_building(plot_data: Dictionary, building_type: String) -> bool:
	if plot_data["is_occupied"]:
		return false
	
	var district_id = plot_data["district_id"]
	match building_type:
		"workshop":
			return district_id == 1 or district_id == 2
		"club":
			return district_id == 0 or district_id == 3
		"ngo":
			return district_id != 1
		_:
			return true

func get_incompatibility_reason(plot_data: Dictionary, building_type: String) -> String:
	if plot_data["is_occupied"]:
		return "Plot occupied"
	
	var district_id = plot_data["district_id"]
	match building_type:
		"workshop":
			if district_id != 1 and district_id != 2:
				return "Better in Industrial/Residential"
		"club":
			if district_id != 0 and district_id != 3:
				return "Better in Downtown/Waterfront"
		"ngo":
			if district_id == 1:
				return "Not suitable for Industrial"
	
	return "Unknown restriction"

func get_district_bonuses(district_id: int) -> String:
	match district_id:
		0: return "+50% Income, +30% Heat"
		1: return "Workshop bonus, -30% Heat"
		2: return "Steady income, Neighborhood watch"
		3: return "+30% Nightlife, Smuggling routes"
		_: return ""
