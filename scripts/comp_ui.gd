extends Control

@onready var label = $RichTextLabel
@onready var label2 = $RichTextLabel2
@onready var background = $Background

func _ready():
	background.visible = false  # Start hidden
	label.visible = false
	label2.visible = false
	
func show_comp():
	print("show_comp() called!")  # Debugging print
	label.visible = true
	background.visible = true 
	print("NoteUI should be visible now!")
	
func hide_comp():
	print("Closing NoteUI from signal")  # Debugging print
	label.visible = false
	label2.visible = false
	background.visible = false  # Hide UI when a note is closed
	
func go_next():
	label.visible = false
	label2.visible = true
