# PauseMenu.gd
extends Control

func _ready() -> void:
	# Hide the pause menu by default.
	hide()
	# Ensure the pause menu processes even when the game is paused.
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _input(event):
	if event.is_action_pressed("cancel"):
		get_tree().paused = false
		hide()

func _on_settings_button_pressed() -> void:
	# SettingsPanel.show()
	pass


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_resume_button_pressed() -> void:
	get_tree().paused = false
	hide()
