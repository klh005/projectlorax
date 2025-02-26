extends Area3D

@export var note_text: String = "This is a 3D note."
@onready var interaction_label = $"../NoteUI/InteractionLabel"

signal note_closed
signal note_opened(text)
var is_open = false  # Tracks if the note is currently open

func on_looked_at():
	interaction_label.text = "Press [E] to interact"
	interaction_label.visible = true
	#print("Looking at the note!")

func open_note():
	print("Opening note: ", note_text)
	note_opened.emit(note_text)  # Emit signal to show the note UI
	is_open = true

func close_note():
	print("Closing note")
	note_closed.emit()  # Signal UI to close
	is_open = false
