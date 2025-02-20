extends Node3D

@onready var note_ui = $NoteUI  # Adjust if needed

func _ready():
	# Connects notes to NoteUI
	for note in get_tree().get_nodes_in_group("notes"):
		#print("Found note:", note.name)
		note.note_opened.connect(note_ui.show_note)  # Connect open signal
		note.note_closed.connect(note_ui.hide_note)  # Connect close signal
	#print("All notes connected successfully!")
