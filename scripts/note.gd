extends Area3D

@onready var interaction_label = $"../UI/NoteUI/InteractionLabel"

signal note_closed
signal note_opened()
var is_open = false  # Tracks if the note is currently open

func on_looked_at():
	interaction_label.text = "Press [E] to interact"
	interaction_label.visible = true
	#print("Looking at the note!")

func open_note(text):
	print("Opening note: ")
	note_opened.emit(text)  # Emit signal to show the note UI
	is_open = true

func close_note():
	print("Closing note")
	note_closed.emit()  # Signal UI to close
	is_open = false
