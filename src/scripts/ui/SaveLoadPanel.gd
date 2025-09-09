extends Control
class_name SaveLoadPanel

signal save_requested(slot: int, name: String)
signal load_requested(slot: int)
signal delete_requested(slot: int)

var background: ColorRect
var title_label: Label
var save_slots_container: VBoxContainer
var close_button: Button
var mode_label: Label

var save_system: SaveSystem
var current_mode: String = "save"  # "save" or "load"

func _ready() -> void:
	setup_panel()
	setup_save_system()
	visible = false
	modulate.a = 0.0

func setup_panel() -> void:
	# Main background
	background = ColorRect.new()
	background.color = Color(0.1, 0.1, 0.1, 0.95)
	background.size = Vector2(600, 700)
	background.position = Vector2(50, 50)
	add_child(background)
	
	# Title
	title_label = Label.new()
	title_label.text = "Save Game"
	title_label.position = Vector2(20, 20)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	background.add_child(title_label)
	
	# Mode indicator
	mode_label = Label.new()
	mode_label.text = "Select a slot to save your game"
	mode_label.position = Vector2(20, 60)
	mode_label.add_theme_font_size_override("font_size", 14)
	mode_label.add_theme_color_override("font_color", Color.GRAY)
	background.add_child(mode_label)
	
	# Close button
	close_button = Button.new()
	close_button.text = "Close"
	close_button.size = Vector2(80, 40)
	close_button.position = Vector2(500, 20)
	close_button.pressed.connect(hide_panel)
	background.add_child(close_button)
	
	# Scroll container for save slots
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 100)
	scroll.size = Vector2(560, 580)
	background.add_child(scroll)
	
	# Container for save slots
	save_slots_container = VBoxContainer.new()
	save_slots_container.size = Vector2(540, 580)
	scroll.add_child(save_slots_container)

func setup_save_system() -> void:
	save_system = SaveSystem.new()
	add_child(save_system)
	
	save_system.save_completed.connect(_on_save_completed)
	save_system.load_completed.connect(_on_load_completed)
	save_system.save_deleted.connect(_on_save_deleted)

func show_save_panel() -> void:
	current_mode = "save"
	title_label.text = "Save Game"
	mode_label.text = "Select a slot to save your game"
	show_panel()
	# Refresh after panel is shown to avoid initialization conflicts
	call_deferred("refresh_save_slots")

func show_load_panel() -> void:
	current_mode = "load"
	title_label.text = "Load Game"
	mode_label.text = "Select a save to load"
	show_panel()
	# Refresh after panel is shown to avoid initialization conflicts
	call_deferred("refresh_save_slots")

func show_panel() -> void:
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_panel() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): visible = false)

func refresh_save_slots() -> void:
	# Clear existing slots
	for child in save_slots_container.get_children():
		child.queue_free()
	
	# Wait for deletion
	await get_tree().process_frame
	
	# Get save information
	var saves_info = save_system.get_all_saves_info()
	
	# Create slot UI for each save
	for save_info in saves_info:
		create_save_slot_ui(save_info)

func create_save_slot_ui(save_info: Dictionary) -> void:
	var slot_panel = ColorRect.new()
	slot_panel.color = Color(0.2, 0.2, 0.2, 0.8)
	slot_panel.size = Vector2(520, 100)
	
	var slot_number = save_info.get("slot", 0)
	var is_empty = save_info.get("is_empty", false)
	
	if is_empty:
		slot_panel.color = Color(0.15, 0.15, 0.15, 0.6)
	
	# Slot title
	var slot_title = Label.new()
	slot_title.text = save_info.get("save_name", "Empty Slot")
	slot_title.position = Vector2(15, 10)
	slot_title.add_theme_font_size_override("font_size", 16)
	slot_title.add_theme_color_override("font_color", Color.WHITE if not is_empty else Color.GRAY)
	slot_panel.add_child(slot_title)
	
	if not is_empty:
		# Date/time
		var datetime_label = Label.new()
		datetime_label.text = save_system.format_timestamp(save_info.get("timestamp", 0))
		datetime_label.position = Vector2(15, 35)
		datetime_label.add_theme_font_size_override("font_size", 12)
		datetime_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		slot_panel.add_child(datetime_label)
		
		# Game info
		var info_label = Label.new()
		info_label.text = "Day %d | $%s | %s" % [
			save_info.get("day", 1),
			format_money(save_info.get("money", 0)),
			save_system.format_playtime(save_info.get("playtime", 0.0))
		]
		info_label.position = Vector2(15, 55)
		info_label.add_theme_font_size_override("font_size", 12)
		info_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		slot_panel.add_child(info_label)
	
	# Action buttons
	if current_mode == "save":
		# Save button
		var save_button = Button.new()
		save_button.text = "Save" if is_empty else "Overwrite"
		save_button.size = Vector2(100, 30)
		save_button.position = Vector2(300, 35)
		save_button.pressed.connect(func(): _on_save_slot_pressed(slot_number, save_info.get("save_name", "")))
		slot_panel.add_child(save_button)
		
		# Quick save with custom name
		if is_empty:
			var name_input = LineEdit.new()
			name_input.placeholder_text = "Save name..."
			name_input.size = Vector2(150, 30)
			name_input.position = Vector2(130, 35)
			name_input.text_submitted.connect(func(text): _on_save_slot_pressed(slot_number, text))
			slot_panel.add_child(name_input)
	
	elif current_mode == "load" and not is_empty:
		# Load button
		var load_button = Button.new()
		load_button.text = "Load"
		load_button.size = Vector2(80, 30)
		load_button.position = Vector2(300, 35)
		load_button.pressed.connect(func(): _on_load_slot_pressed(slot_number))
		slot_panel.add_child(load_button)
	
	# Delete button (for non-empty slots)
	if not is_empty:
		var delete_button = Button.new()
		delete_button.text = "Delete"
		delete_button.size = Vector2(80, 30)
		delete_button.position = Vector2(420, 35)
		delete_button.modulate = Color.RED
		delete_button.pressed.connect(func(): _on_delete_slot_pressed(slot_number))
		slot_panel.add_child(delete_button)
	
	save_slots_container.add_child(slot_panel)
	
	# Add spacing
	var spacer = Control.new()
	spacer.size = Vector2(520, 10)
	save_slots_container.add_child(spacer)

func _on_save_slot_pressed(slot: int, name: String) -> void:
	if name.strip_edges() == "":
		name = "Save " + str(slot)
	
	save_requested.emit(slot, name)
	save_system.save_game(slot, name)

func _on_load_slot_pressed(slot: int) -> void:
	load_requested.emit(slot)
	save_system.load_game(slot)

func _on_delete_slot_pressed(slot: int) -> void:
	# Confirmation dialog would be nice, but for now just delete
	delete_requested.emit(slot)
	save_system.delete_save(slot)

func _on_save_completed(slot: int, success: bool) -> void:
	if success:
		EventBus.notify_success("Game saved to slot " + str(slot))
		refresh_save_slots()
	else:
		EventBus.notify_error("Failed to save game")

func _on_load_completed(slot: int, success: bool) -> void:
	if success:
		EventBus.notify_success("Game loaded from slot " + str(slot))
		hide_panel()
	else:
		EventBus.notify_error("Failed to load game")

func _on_save_deleted(slot: int) -> void:
	EventBus.notify("Save slot " + str(slot) + " deleted", "info")
	refresh_save_slots()

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return str(snapped(amount / 1000000.0, 0.1)) + "M"
	elif amount >= 1000:
		return str(snapped(amount / 1000.0, 0.1)) + "K"
	else:
		return str(int(amount))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		hide_panel()