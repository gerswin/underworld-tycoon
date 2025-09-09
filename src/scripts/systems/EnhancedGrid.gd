extends Node2D
class_name EnhancedGrid

signal grid_cell_hovered(grid_pos: Vector2i)
signal grid_cell_clicked(grid_pos: Vector2i)

var grid_size: int = 64
var map_width: int = 100
var map_height: int = 100

var grid_lines: Node2D
var grid_highlights: Node2D
var construction_preview: Node2D

var is_visible: bool = false
var highlight_color: Color = Color.YELLOW
var snap_enabled: bool = true

func _ready() -> void:
	setup_grid_layers()

func setup_grid_layers() -> void:
	# Grid lines layer
	grid_lines = Node2D.new()
	grid_lines.name = "GridLines"
	add_child(grid_lines)
	
	# Highlights layer
	grid_highlights = Node2D.new()
	grid_highlights.name = "GridHighlights"
	add_child(grid_highlights)
	
	# Construction preview layer
	construction_preview = Node2D.new()
	construction_preview.name = "ConstructionPreview"
	add_child(construction_preview)
	
	generate_grid_visuals()

func generate_grid_visuals() -> void:
	# Clear existing grid
	for child in grid_lines.get_children():
		child.queue_free()
	
	# Create major and minor grid lines
	create_grid_lines()
	
	# Create area for mouse detection
	setup_mouse_detection()

func create_grid_lines() -> void:
	# Minor grid lines (every cell)
	for x in range(map_width + 1):
		var line = Line2D.new()
		line.add_point(Vector2(x * grid_size, 0))
		line.add_point(Vector2(x * grid_size, map_height * grid_size))
		line.width = 1.0
		line.default_color = Color.WHITE.darkened(0.7)
		line.default_color.a = 0.3
		grid_lines.add_child(line)
	
	for y in range(map_height + 1):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * grid_size))
		line.add_point(Vector2(map_width * grid_size, y * grid_size))
		line.width = 1.0
		line.default_color = Color.WHITE.darkened(0.7)
		line.default_color.a = 0.3
		grid_lines.add_child(line)
	
	# Major grid lines (every 5 cells)
	for x in range(0, map_width + 1, 5):
		var line = Line2D.new()
		line.add_point(Vector2(x * grid_size, 0))
		line.add_point(Vector2(x * grid_size, map_height * grid_size))
		line.width = 2.0
		line.default_color = Color.WHITE.darkened(0.5)
		line.default_color.a = 0.5
		grid_lines.add_child(line)
	
	for y in range(0, map_height + 1, 5):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * grid_size))
		line.add_point(Vector2(map_width * grid_size, y * grid_size))
		line.width = 2.0
		line.default_color = Color.WHITE.darkened(0.5)
		line.default_color.a = 0.5
		grid_lines.add_child(line)

func setup_mouse_detection() -> void:
	# Create invisible area for mouse detection with lower priority
	var area = Area2D.new()
	area.name = "MouseDetection"
	area.priority = 1  # Lower priority than plot areas
	
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(map_width * grid_size, map_height * grid_size)
	collision.shape = shape
	collision.position = Vector2(map_width * grid_size / 2, map_height * grid_size / 2)
	
	area.add_child(collision)
	grid_lines.add_child(area)
	
	# Set collision layer to avoid conflicts (use layer 1 which is World)
	area.collision_layer = 1  # World layer (matches project settings)  
	area.collision_mask = 0
	
	# Connect mouse events
	area.mouse_entered.connect(_on_grid_mouse_entered)
	area.mouse_exited.connect(_on_grid_mouse_exited)

func _process(_delta: float) -> void:
	if is_visible:
		update_mouse_highlight()

func update_mouse_highlight() -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	
	# Check if mouse is within grid bounds
	if grid_pos.x >= 0 and grid_pos.x < map_width and grid_pos.y >= 0 and grid_pos.y < map_height:
		highlight_cell(grid_pos)
		grid_cell_hovered.emit(grid_pos)

func highlight_cell(grid_pos: Vector2i) -> void:
	clear_highlights()
	
	var world_pos = grid_to_world(grid_pos)
	var highlight = ColorRect.new()
	highlight.size = Vector2(grid_size, grid_size)
	highlight.position = world_pos - highlight.size / 2
	highlight.color = highlight_color
	highlight.color.a = 0.3
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	grid_highlights.add_child(highlight)

func clear_highlights() -> void:
	for child in grid_highlights.get_children():
		child.queue_free()

func show_construction_preview(grid_pos: Vector2i, building_type: String, is_valid: bool) -> void:
	clear_construction_preview()
	
	var world_pos = grid_to_world(grid_pos)
	var preview = create_building_preview(building_type, is_valid)
	preview.position = world_pos
	
	construction_preview.add_child(preview)

func create_building_preview(building_type: String, is_valid: bool) -> Node2D:
	var preview_node = Node2D.new()
	
	# Main building shape
	var building_rect = ColorRect.new()
	building_rect.size = Vector2(grid_size * 0.8, grid_size * 0.8)
	building_rect.position = -building_rect.size / 2
	
	# Set color based on building type and validity
	var base_color: Color
	match building_type:
		"bar":
			base_color = Color(0.6, 0.4, 0.2)
		"club":
			base_color = Color(0.5, 0.2, 0.5)
		"workshop":
			base_color = Color(0.3, 0.3, 0.3)
		"ngo":
			base_color = Color(0.3, 0.5, 0.7)
		_:
			base_color = Color.WHITE
	
	# Modify color based on validity
	if is_valid:
		building_rect.color = base_color.lightened(0.2)
		building_rect.color.a = 0.8
	else:
		building_rect.color = Color.RED
		building_rect.color.a = 0.6
	
	preview_node.add_child(building_rect)
	
	# Add validity indicator
	var indicator = ColorRect.new()
	indicator.size = Vector2(grid_size * 0.2, grid_size * 0.2)
	indicator.position = Vector2(building_rect.size.x / 2 - indicator.size.x, -building_rect.size.y / 2)
	indicator.color = Color.GREEN if is_valid else Color.RED
	preview_node.add_child(indicator)
	
	# Add type icon
	var icon_label = Label.new()
	icon_label.position = Vector2(-10, -30)
	icon_label.add_theme_font_size_override("font_size", 20)
	
	match building_type:
		"bar":
			icon_label.text = "🍺"
		"club":
			icon_label.text = "🎵"
		"workshop":
			icon_label.text = "⚙"
		"ngo":
			icon_label.text = "💙"
		_:
			icon_label.text = "?"
	
	preview_node.add_child(icon_label)
	
	return preview_node

func clear_construction_preview() -> void:
	for child in construction_preview.get_children():
		child.queue_free()

func show_grid() -> void:
	is_visible = true
	visible = true
	modulate.a = 1.0

func hide_grid() -> void:
	is_visible = false
	clear_highlights()
	clear_construction_preview()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_property(self, "visible", false, 0.0)

func toggle_grid() -> void:
	if is_visible:
		hide_grid()
	else:
		show_grid()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / grid_size), int(world_pos.y / grid_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * grid_size + grid_size / 2, grid_pos.y * grid_size + grid_size / 2)

func snap_to_grid(world_pos: Vector2) -> Vector2:
	if snap_enabled:
		var grid_pos = world_to_grid(world_pos)
		return grid_to_world(grid_pos)
	return world_pos

func is_grid_position_valid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < map_width and grid_pos.y >= 0 and grid_pos.y < map_height

func get_grid_bounds() -> Rect2i:
	return Rect2i(0, 0, map_width, map_height)

func _on_grid_mouse_entered() -> void:
	if is_visible:
		show_grid()

func _on_grid_mouse_exited() -> void:
	clear_highlights()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible and event.is_action_pressed("left_click"):
		var mouse_pos = get_global_mouse_position()
		var grid_pos = world_to_grid(mouse_pos)
		if is_grid_position_valid(grid_pos):
			grid_cell_clicked.emit(grid_pos)