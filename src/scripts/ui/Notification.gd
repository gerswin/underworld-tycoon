extends PanelContainer

@onready var icon_label: Label = $MarginContainer/HBoxContainer/Icon
@onready var message_label: Label = $MarginContainer/HBoxContainer/Message

var fade_timer: Timer
var display_time: float = 3.0

func _ready() -> void:
	modulate.a = 0.0
	create_fade_timer()
	fade_in()

func setup(text: String, type: String = "info") -> void:
	message_label.text = text
	
	match type:
		"success":
			icon_label.text = "✓"
			icon_label.modulate = Color.GREEN
			message_label.modulate = Color.GREEN
		"warning":
			icon_label.text = "⚠"
			icon_label.modulate = Color.YELLOW
			message_label.modulate = Color.YELLOW
		"error":
			icon_label.text = "✗"
			icon_label.modulate = Color.RED
			message_label.modulate = Color.RED
		_:
			icon_label.text = "ℹ"
			icon_label.modulate = Color.WHITE
			message_label.modulate = Color.WHITE

func create_fade_timer() -> void:
	fade_timer = Timer.new()
	fade_timer.wait_time = display_time
	fade_timer.one_shot = true
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	add_child(fade_timer)

func fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_callback(fade_timer.start)

func _on_fade_timer_timeout() -> void:
	fade_out()

func fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
