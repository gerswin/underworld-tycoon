extends Node2D
class_name EffectsManager

func create_floating_text(position: Vector2, amount: float, is_income: bool = true) -> void:
	var floating_text = FloatingText.new()
	floating_text.position = position
	floating_text.setup_money(amount, is_income)
	add_child(floating_text)

func create_floating_message(position: Vector2, message: String, color: Color = Color.WHITE) -> void:
	var floating_text = FloatingText.new()
	floating_text.position = position
	floating_text.setup_text(message, color)
	add_child(floating_text)

func create_building_effect(position: Vector2, effect_type: String) -> void:
	match effect_type:
		"construction_complete":
			create_floating_message(position, "Complete!", Color.GREEN)
			create_sparkle_effect(position)
		"raided":
			create_floating_message(position, "RAIDED!", Color.RED)
			create_smoke_effect(position)
		"upgrade":
			create_floating_message(position, "Upgraded!", Color.GOLD)
			create_shine_effect(position)

func create_sparkle_effect(position: Vector2) -> void:
	for i in range(5):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.YELLOW
		particle.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		add_child(particle)
		
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", 
			particle.position + Vector2(randf_range(-50, 50), randf_range(-50, 50)), 1.0)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(particle.queue_free)

func create_smoke_effect(position: Vector2) -> void:
	for i in range(3):
		var smoke = ColorRect.new()
		smoke.size = Vector2(8, 8)
		smoke.color = Color.GRAY
		smoke.position = position + Vector2(randf_range(-10, 10), 0)
		add_child(smoke)
		
		var tween = create_tween()
		tween.parallel().tween_property(smoke, "position:y", smoke.position.y - 40, 2.0)
		tween.parallel().tween_property(smoke, "modulate:a", 0.0, 2.0)
		tween.parallel().tween_property(smoke, "scale", Vector2(2, 2), 2.0)
		tween.tween_callback(smoke.queue_free)
		await tween.finished

func create_shine_effect(position: Vector2) -> void:
	var shine = ColorRect.new()
	shine.size = Vector2(20, 20)
	shine.color = Color.GOLD
	shine.position = position - shine.size / 2
	add_child(shine)
	
	var tween = create_tween()
	tween.parallel().tween_property(shine, "scale", Vector2(2, 2), 0.5)
	tween.parallel().tween_property(shine, "modulate:a", 0.0, 0.5)
	tween.tween_callback(shine.queue_free)

func create_heat_warning_effect(position: Vector2) -> void:
	var warning = Label.new()
	warning.text = "⚠ HEAT ⚠"
	warning.position = position
	warning.modulate = Color.RED
	warning.add_theme_font_size_override("font_size", 20)
	add_child(warning)
	
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(warning, "modulate:a", 0.3, 0.2)
	tween.tween_property(warning, "modulate:a", 1.0, 0.2)
	tween.tween_callback(warning.queue_free)