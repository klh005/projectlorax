extends Control

func _ready() -> void:
	# Ensure the mouse cursor is visible in the menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	print("Main menu ready!")
	
	# Ensure buttons are connected
	if !$Panel/PlayButton.is_connected("pressed", Callable(self, "_on_play_button_pressed")):
		$Panel/PlayButton.connect("pressed", Callable(self, "_on_play_button_pressed"))
	
	if !$Panel/QuitButton.is_connected("pressed", Callable(self, "_on_quit_button_pressed")):
		$Panel/QuitButton.connect("pressed", Callable(self, "_on_quit_button_pressed"))

func _on_play_button_pressed() -> void:
	print("Play button pressed!")
	# Change scene to your game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_button_pressed() -> void:
	print("Quit button pressed!")
	get_tree().quit()
