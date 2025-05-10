extends Control

func _ready():
	visible = false  # Start hidden
	
	# Connect button signals if not already connected
	for button_name in ["ResumeButton", "SettingsButton", "MainMenuButton", "ExitButton"]:
		var button = get_node_or_null("Panel/" + button_name)
		if button:
			var method_name = "_on_" + button_name.to_snake_case() + "_pressed"
			if !button.is_connected("pressed", Callable(self, method_name)):
				button.connect("pressed", Callable(self, method_name))

func _on_resume_button_pressed() -> void:
	print("Resume button pressed")
	hide_pm()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Resume player movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(false)

func _on_settings_button_pressed() -> void:
	# Toggle settings panel visibility
	var settings_panel = get_node_or_null("Panel/SettingsPanel")
	if settings_panel:
		settings_panel.visible = !settings_panel.visible

func _on_main_menu_button_pressed() -> void:
	var confirmation_dialog = get_node_or_null("/root/Main/UI/ConfirmationDialog")
	if confirmation_dialog and confirmation_dialog.has_method("show_dialog"):
		confirmation_dialog.show_dialog("Return to main menu? Any unsaved progress will be lost.", Callable(self, "_confirm_main_menu"))
	else:
		_confirm_main_menu()  # No confirmation dialog, just proceed

func _confirm_main_menu() -> void:
	# Unpause and change scene to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")

func _on_exit_button_pressed() -> void:
	var confirmation_dialog = get_node_or_null("/root/Main/UI/ConfirmationDialog")
	if confirmation_dialog and confirmation_dialog.has_method("show_dialog"):
		confirmation_dialog.show_dialog("Exit game? Any unsaved progress will be lost.", Callable(self, "_confirm_exit"))
	else:
		_confirm_exit()  # No confirmation dialog, just proceed

func _confirm_exit() -> void:
	get_tree().quit()

func show_pm():
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Pause player movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(true)

func hide_pm():
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Resume player movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(false)
