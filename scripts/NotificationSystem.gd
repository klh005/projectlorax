# NotificationSystem.gd
extends Control

@onready var notification_label = $NotificationLabel

var current_notification = null
var notification_queue = []

func _ready():
	# Create UI if not present
	if not has_node("NotificationLabel"):
		var label = Label.new()
		label.name = "NotificationLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_top = 0.2  # Position at top quarter of screen
		label.anchor_bottom = 0.3
		label.anchor_left = 0.1
		label.anchor_right = 0.9
		label.modulate = Color(1, 0.2, 0.2)  # Red warning color
		add_child(label)
		notification_label = label
	
	hide()

func show_notification(text, duration = 3.0):
	# Queue the notification if one is already showing
	if visible:
		notification_queue.append({"text": text, "duration": duration})
		return
	
	current_notification = {"text": text, "duration": duration}
	notification_label.text = text
	
	# Simple fade-in without animation
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	show()
	
	# Wait for duration then fade out
	await get_tree().create_timer(duration).timeout
	
	var fade_out_tween = create_tween()
	fade_out_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await fade_out_tween.finished
	
	hide()
	current_notification = null
	
	# Process any queued notifications
	if notification_queue.size() > 0:
		var next = notification_queue.pop_front()
		show_notification(next.text, next.duration)
