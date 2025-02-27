extends Area3D

#@export var note_text: String = "This is a 3D note."
@onready var interaction_label = $"../UI/CompUI/InteractionLabel"

signal comp_opened
signal comp_closed
var is_open = false  # Tracks if the note is currently open

func look_comp():
	interaction_label.text = "Press [E] to interact"
	interaction_label.visible = true
	#print("callign lookcomp")
	#print("Looking at the note!")

func open_comp():
	print("Opening computer")
	comp_opened.emit()  # Emit signal to show the note UI
	is_open = true

func close_comp():
	print("Closing computer")
	comp_closed.emit()  # Signal UI to close
	is_open = false
