# GameState.gd
extends Node

# Game progression variables
var current_level: int = 1
var collected_notes: Array = []
var game_difficulty: String = "normal"

# Runtime state
var is_game_paused: bool = false
var jumpscare_in_progress: bool = false

func _ready() -> void:
	# Initialize default game state
	reset()

func reset() -> void:
	# Reset all game state variables to default
	current_level = 1
	collected_notes = []
	is_game_paused = false
	jumpscare_in_progress = false
	
	print("GameState: Game state has been reset")

func add_collected_note(note_id: String) -> void:
	if not collected_notes.has(note_id):
		collected_notes.append(note_id)
		print("GameState: Note collected: ", note_id)

func is_note_collected(note_id: String) -> bool:
	return collected_notes.has(note_id)
	
func handle_jumpscare_begin() -> void:
	jumpscare_in_progress = true
	
func handle_jumpscare_end() -> void:
	jumpscare_in_progress = false
