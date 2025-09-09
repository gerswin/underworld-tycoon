extends Node2D
class_name Building

signal clicked(building)
signal income_generated(amount)

@export var business_data: Dictionary = {}

var is_active: bool = true
var is_under_construction: bool = true
var construction_progress: float = 0.0
var accumulated_income: float = 0.0

var base_sprite: Sprite2D
var icon_sprite: Sprite2D
var progress_bar: ProgressBar
var income_label: Label

func _ready() -> void:
	setup_visuals()
	setup_interaction()
	if business_data.has("build_time"):
		start_construction()

func setup_visuals() -> void:
	# Base building sprite
	base_sprite = Sprite2D.new()
	var base_texture = create_building_texture()
	base_sprite.texture = base_texture
	add_child(base_sprite)
	
	# Icon to identify building type
	icon_sprite = Sprite2D.new()
	icon_sprite.texture = create_icon_texture()
	icon_sprite.position.y = -20
	icon_sprite.scale = Vector2(0.5, 0.5)
	add_child(icon_sprite)
	
	# Progress bar for construction
	progress_bar = ProgressBar.new()
	progress_bar.size = Vector2(60, 8)
	progress_bar.position = Vector2(-30, 25)
	progress_bar.value = 0
	progress_bar.visible = false
	add_child(progress_bar)
	
	# Income popup label
	income_label = Label.new()
	income_label.add_theme_font_size_override("font_size", 14)
	income_label.position = Vector2(-20, -40)
	income_label.visible = false
	add_child(income_label)

func create_building_texture() -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var color = get_building_color()
	
	# Draw building base
	for x in range(8, 56):
		for y in range(16, 64):
			image.set_pixel(x, y, color)
	
	# Draw roof
	for x in range(4, 60):
		var roof_y = 16 - (abs(32 - x) / 4)
		for y in range(int(roof_y), 16):
			image.set_pixel(x, y, color.darkened(0.2))
	
	# Draw door
	for x in range(26, 38):
		for y in range(44, 64):
			image.set_pixel(x, y, Color(0.3, 0.2, 0.1))
	
	# Draw windows
	for window_x in [16, 40]:
		for x in range(window_x, window_x + 8):
			for y in range(24, 32):
				image.set_pixel(x, y, Color(0.6, 0.8, 1.0, 0.8))
	
	return ImageTexture.create_from_image(image)

func create_icon_texture() -> ImageTexture:
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var icon_color = Color.WHITE
	
	match business_data.get("type", ""):
		"bar":
			# Draw beer mug icon
			icon_color = Color(1.0, 0.8, 0.2)
			for x in range(10, 22):
				for y in range(8, 24):
					image.set_pixel(x, y, icon_color)
		"club":
			# Draw music note icon
			icon_color = Color(1.0, 0.2, 0.8)
			for x in range(14, 18):
				for y in range(8, 20):
					image.set_pixel(x, y, icon_color)
		"workshop":
			# Draw gear icon
			icon_color = Color(0.6, 0.6, 0.6)
			for x in range(8, 24):
				for y in range(8, 24):
					if (x - 16) * (x - 16) + (y - 16) * (y - 16) < 64:
						image.set_pixel(x, y, icon_color)
		"ngo":
			# Draw heart icon
			icon_color = Color(0.2, 0.6, 1.0)
			for x in range(8, 24):
				for y in range(10, 22):
					if abs(x - 16) + abs(y - 14) < 8:
						image.set_pixel(x, y, icon_color)
	
	return ImageTexture.create_from_image(image)

func get_building_color() -> Color:
	match business_data.get("type", ""):
		"bar":
			return Color(0.6, 0.4, 0.2)  # Brown
		"club":
			return Color(0.5, 0.2, 0.5)  # Purple
		"workshop":
			return Color(0.3, 0.3, 0.3)  # Dark gray
		"ngo":
			return Color(0.3, 0.5, 0.7)  # Blue
		_:
			return Color(0.5, 0.5, 0.5)  # Default gray

func setup_interaction() -> void:
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)
	
	area.input_event.connect(_on_area_input_event)
	area.mouse_entered.connect(_on_mouse_entered)
	area.mouse_exited.connect(_on_mouse_exited)

func start_construction() -> void:
	is_under_construction = true
	is_active = false
	progress_bar.visible = true
	base_sprite.modulate = Color(1, 1, 1, 0.5)
	
	var build_time = business_data.get("build_time", 2.0)  # Construcción más rápida para testing
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, build_time)
	tween.tween_callback(complete_construction)

func complete_construction() -> void:
	is_under_construction = false
	is_active = true
	progress_bar.visible = false
	base_sprite.modulate = Color.WHITE
	EventBus.notify_success(business_data.get("type", "Building").capitalize() + " construction completed!")
	
	# Find effects manager and show completion effect
	var main_scene = get_tree().get_root().get_node("Main")
	if main_scene and main_scene.has_method("get") and main_scene.effects_manager:
		main_scene.effects_manager.create_building_effect(global_position, "construction_complete")

func generate_income(amount: float) -> void:
	if !is_active or is_under_construction:
		return
	
	accumulated_income += amount
	income_generated.emit(amount)
	show_income_popup(amount)

func show_income_popup(amount: float) -> void:
	income_label.text = "+$" + str(int(amount))
	income_label.modulate = Color.GREEN
	income_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(income_label, "position:y", income_label.position.y - 20, 1.0)
	tween.parallel().tween_property(income_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): income_label.visible = false; income_label.position.y += 20; income_label.modulate.a = 1.0)

func set_active(active: bool) -> void:
	is_active = active
	if active:
		base_sprite.modulate = Color.WHITE
	else:
		base_sprite.modulate = Color(0.5, 0.5, 0.5)

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		clicked.emit(self)

func _on_mouse_entered() -> void:
	base_sprite.modulate = base_sprite.modulate.lightened(0.2)

func _on_mouse_exited() -> void:
	if is_active and !is_under_construction:
		base_sprite.modulate = Color.WHITE
	elif is_under_construction:
		base_sprite.modulate = Color(1, 1, 1, 0.5)
	else:
		base_sprite.modulate = Color(0.5, 0.5, 0.5)

func on_cycle_changed(is_day: bool) -> void:
	# Special glow for clubs at night
	if business_data.get("type") == "club" and !is_day:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(base_sprite, "modulate", Color(1.2, 1.0, 1.2), 1.0)
		tween.tween_property(base_sprite, "modulate", Color.WHITE, 1.0)
	elif is_day and business_data.get("type") == "club":
		base_sprite.modulate = Color.WHITE