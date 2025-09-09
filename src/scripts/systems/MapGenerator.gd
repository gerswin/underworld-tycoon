extends Node
class_name MapGenerator

# Map dimensions in tiles
const MAP_WIDTH = 100
const MAP_HEIGHT = 100
const TILE_SIZE = 64

# District colors for visualization
const DISTRICT_COLORS = {
	0: Color(0.3, 0.3, 0.5, 0.8),  # Downtown - Blue-ish
	1: Color(0.4, 0.3, 0.2, 0.8),  # Industrial - Brown
	2: Color(0.2, 0.4, 0.2, 0.8),  # Residential - Green
	3: Color(0.2, 0.3, 0.4, 0.8)   # Waterfront - Cyan-ish
}

# Generate a visual representation of districts
static func generate_district_visuals(parent: Node2D) -> void:
	var half_width = MAP_WIDTH / 2
	var half_height = MAP_HEIGHT / 2
	
	# Create district visualizations
	for district_id in range(4):
		var district_rect = ColorRect.new()
		district_rect.name = "District_" + str(district_id)
		
		# Calculate district bounds
		var rect_pos = Vector2.ZERO
		var rect_size = Vector2(half_width * TILE_SIZE, half_height * TILE_SIZE)
		
		match district_id:
			0:  # Top-left
				rect_pos = Vector2(0, 0)
			1:  # Top-right
				rect_pos = Vector2(half_width * TILE_SIZE, 0)
			2:  # Bottom-left
				rect_pos = Vector2(0, half_height * TILE_SIZE)
			3:  # Bottom-right
				rect_pos = Vector2(half_width * TILE_SIZE, half_height * TILE_SIZE)
		
		district_rect.position = rect_pos
		district_rect.size = rect_size
		district_rect.color = DISTRICT_COLORS[district_id]
		district_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		parent.add_child(district_rect)
		
		# Add district label
		var label = Label.new()
		label.text = _get_district_name(district_id)
		label.position = rect_pos + Vector2(20, 20)
		label.add_theme_font_size_override("font_size", 24)
		label.modulate = Color.WHITE
		parent.add_child(label)

# Generate grid overlay for building placement
static func generate_grid_overlay(parent: Node2D) -> Node2D:
	var grid_container = Node2D.new()
	grid_container.name = "GridOverlay"
	grid_container.modulate.a = 0.2  # Semi-transparent
	
	# Create grid lines
	for x in range(MAP_WIDTH + 1):
		var line = Line2D.new()
		line.add_point(Vector2(x * TILE_SIZE, 0))
		line.add_point(Vector2(x * TILE_SIZE, MAP_HEIGHT * TILE_SIZE))
		line.width = 1.0
		line.default_color = Color.WHITE
		grid_container.add_child(line)
	
	for y in range(MAP_HEIGHT + 1):
		var line = Line2D.new()
		line.add_point(Vector2(0, y * TILE_SIZE))
		line.add_point(Vector2(MAP_WIDTH * TILE_SIZE, y * TILE_SIZE))
		line.width = 1.0
		line.default_color = Color.WHITE
		grid_container.add_child(line)
	
	parent.add_child(grid_container)
	return grid_container

static func _get_district_name(district_id: int) -> String:
	match district_id:
		0: return "Downtown"
		1: return "Industrial"
		2: return "Residential"
		3: return "Waterfront"
		_: return "Unknown"

# Create road network (simple version)
static func generate_roads(parent: Node2D) -> void:
	var roads_container = Node2D.new()
	roads_container.name = "Roads"
	
	# Main horizontal road
	var h_road = ColorRect.new()
	h_road.position = Vector2(0, (MAP_HEIGHT / 2 - 1) * TILE_SIZE)
	h_road.size = Vector2(MAP_WIDTH * TILE_SIZE, TILE_SIZE * 2)
	h_road.color = Color(0.2, 0.2, 0.2)
	roads_container.add_child(h_road)
	
	# Main vertical road
	var v_road = ColorRect.new()
	v_road.position = Vector2((MAP_WIDTH / 2 - 1) * TILE_SIZE, 0)
	v_road.size = Vector2(TILE_SIZE * 2, MAP_HEIGHT * TILE_SIZE)
	v_road.color = Color(0.2, 0.2, 0.2)
	roads_container.add_child(v_road)
	
	# Add road lines
	_add_road_lines(h_road)
	_add_road_lines(v_road)
	
	parent.add_child(roads_container)

static func _add_road_lines(road: ColorRect) -> void:
	var line = Line2D.new()
	line.width = 2.0
	line.default_color = Color.YELLOW
	line.add_point(Vector2(road.size.x / 2, 0))
	line.add_point(Vector2(road.size.x / 2, road.size.y))
	
	if road.size.x > road.size.y:  # Horizontal road
		line.clear_points()
		line.add_point(Vector2(0, road.size.y / 2))
		line.add_point(Vector2(road.size.x, road.size.y / 2))
	
	road.add_child(line)