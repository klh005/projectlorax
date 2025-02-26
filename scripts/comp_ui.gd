extends Control

@onready var label = $RichTextLabel
#@onready var close_button = $Button
@onready var background = $Background

func _ready():
	background.visible = false  # Start hidden
	
func show_comp():
	print("show_comp() called!")  # Debugging print
	#label.text = text  # Set text to the note content
	#label.visible = true
	background.visible = true 
	print("NoteUI should be visible now!")
	
func hide_comp():
	print("Closing NoteUI from signal")  # Debugging print
	label.visible = false
	background.visible = false  # Hide UI when a note is closed
