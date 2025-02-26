extends Node3D

@onready var note_ui = $NoteUI  # Adjust if needed
@onready var comp_ui = $CompUI
@onready var comp = $computer

func _ready():
	# Connects notes to NoteUI
	for note in get_tree().get_nodes_in_group("notes"):
		print("Found note:", note.name)
		note.note_opened.connect(note_ui.show_note)  # Connect open signal
		note.note_closed.connect(note_ui.hide_note)  # Connect close signal
		
	comp.comp_opened.connect(comp_ui.show_comp)
	comp.comp_closed.connect(comp_ui.hide_comp)
	#print("All notes connected successfully!")
