extends Node3D

@onready var note_ui = $UI/NoteUI  # Adjust if needed
@onready var pause_menu: Control = $UI/PauseMenu
@onready var jumpscare_effect = $UI/JumpscareEffect

var is_jumpscare_active = false
@onready var comp_ui = $CompUI
@onready var comp = $computer

func _ready():
	# Reset game state when starting a new game
	if Engine.has_singleton("GameState"):
		var game_state = Engine.get_singleton("GameState")
		game_state.reset()
	
	# Unpause and ensure game is ready to play
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connects notes to NoteUI
	for note in get_tree().get_nodes_in_group("notes"):
		#print("Found note:", note.name)
		note.note_opened.connect(note_ui.show_note)  # Connect open signal
		note.note_closed.connect(note_ui.hide_note)  # Connect close signal
	#print("All notes connected successfully!")
