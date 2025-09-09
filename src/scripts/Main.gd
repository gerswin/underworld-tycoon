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

func _ready() -> void:
	initialize_map()
	setup_camera()
	connect_signals()
	GameManager.start_game()
	print("Main scene initialized")

func initialize_map() -> void:
	# This will be expanded when we have tileset
	print("Map initialized: ", map_width, "x", map_height)

func setup_camera() -> void:
	camera.position = Vector2(map_width * grid_size / 2, map_height * grid_size / 2)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_width * grid_size
	camera.limit_bottom = map_height * grid_size

func connect_signals() -> void:
	EventBus.building_selected.connect(_on_building_selected)
	EventBus.district_clicked.connect(_on_district_clicked)
	GameManager.game_paused.connect(_on_game_paused)

func _process(delta: float) -> void:
	handle_camera_movement(delta)
	if is_placing_building:
		update_building_preview()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		zoom_camera(zoom_speed)
	elif event.is_action_pressed("zoom_out"):
		zoom_camera(-zoom_speed)
	elif event.is_action_pressed("left_click"):
		handle_left_click()
	elif event.is_action_pressed("right_click"):
		cancel_building_placement()

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
		EventBus.notify("Placing " + building_type + ". Click to build, right-click to cancel.")
	else:
		EventBus.notify_error("Not enough dirty money to build " + building_type)

func place_building() -> void:
	var mouse_pos = get_global_mouse_position()
	var grid_pos = world_to_grid(mouse_pos)
	var world_pos = grid_to_world(grid_pos)
	
	if is_valid_building_position(grid_pos):
		var district_id = get_district_at_position(grid_pos)
		var business = ShadowOps.build_business(selected_building_type, district_id, world_pos)
		
		if business.size() > 0:
			Economy.spend_dirty_money(ShadowOps.business_types[selected_building_type]["cost"])
			create_building_visual(business)
			CitySim.add_business_to_district(district_id, business)
			EventBus.notify_success(selected_building_type.capitalize() + " built!")
			EventBus.building_placed.emit(business)
		
		cancel_building_placement()

func cancel_building_placement() -> void:
	is_placing_building = false
	selected_building_type = ""
	current_tool = ""

func create_building_visual(business: Dictionary) -> void:
	# Placeholder for building visual
	# This will be replaced with actual sprites later
	var building_node = ColorRect.new()
	building_node.size = Vector2(grid_size * 0.8, grid_size * 0.8)
	building_node.position = business["position"] - building_node.size / 2
	
	match business["type"]:
		"bar":
			building_node.color = Color.BROWN
		"club":
			building_node.color = Color.PURPLE
		"workshop":
			building_node.color = Color.DARK_GRAY
		"ngo":
			building_node.color = Color.BLUE
		_:
			building_node.color = Color.WHITE
	
	building_node.set_meta("business_data", business)
	buildings_container.add_child(building_node)

func update_building_preview() -> void:
	# This will show a preview of the building at mouse position
	pass

func is_valid_building_position(grid_pos: Vector2i) -> bool:
	# Check if position is within map bounds
	if grid_pos.x < 0 or grid_pos.x >= map_width:
		return false
	if grid_pos.y < 0 or grid_pos.y >= map_height:
		return false
	
	# Check if position is not occupied
	# This will be expanded with actual collision detection
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

func _on_district_clicked(district_id: int) -> void:
	print("District clicked: ", district_id)

func _on_game_paused(is_paused: bool) -> void:
	set_process(!is_paused)