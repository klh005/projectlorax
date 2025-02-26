# GameOver.gd
extends Control

@onready var label: Label = $Label

func _ready() -> void:
	print("GameOver scene is now running!")
	
	# Ensure mouse is visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Fade in effect for smooth transition
	modulate = Color(1, 1, 1, 0)  # Start fully transparent
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 2.0)
	
	# Print debug info to confirm scene is working
	print("GameOver: Scene ready! Displaying Game Over UI.")

func _input(event):
	if event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		print("Input detected, transitioning to main menu")
		# Any key or mouse click returns to main menu
		get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
