extends Label
class_name FloatingText

var velocity: Vector2 = Vector2(0, -50)
var fade_speed: float = 2.0
var gravity: float = 10.0
var lifetime: float = 2.0

func _ready() -> void:
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	
	# Start animation
	animate()

func setup_money(amount: float, is_income: bool = true) -> void:
	if is_income:
		text = "+$" + format_money(amount)
		modulate = Color.GREEN
		velocity = Vector2(randf_range(-20, 20), -50)
	else:
		text = "-$" + format_money(amount)
		modulate = Color.RED
		velocity = Vector2(randf_range(-20, 20), -30)

func setup_text(display_text: String, color: Color = Color.WHITE) -> void:
	text = display_text
	modulate = color
	velocity = Vector2(randf_range(-30, 30), -40)

func animate() -> void:
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", position + velocity * lifetime, lifetime)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_callback(queue_free)

func _process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return str(snapped(amount / 1000000.0, 0.1)) + "M"
	elif amount >= 1000:
		return str(snapped(amount / 1000.0, 0.1)) + "K"
	else:
		return str(int(amount))