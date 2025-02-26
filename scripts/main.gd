extends Node3D

@onready var note_ui = $UI/NoteUI  # Adjust if needed
@onready var pause_menu: Control = $UI/PauseMenu
@onready var jumpscare_effect = $UI/JumpscareEffect

var is_jumpscare_active = false

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
		note.note_opened.connect(note_ui.show_note)  # Connect open signal
		note.note_closed.connect(note_ui.hide_note)  # Connect close signal

func create_jumpscare_effect(enemy):
	if is_jumpscare_active:
		return
	
	is_jumpscare_active = true
	
	# Get the player
	var player = get_node("%Player")
	if not player:
		print("ERROR: Player node not found!")
		return
	
	# Freeze player movement and controls
	player.set_process_input(false)
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	
	# Flash screen effect
	if jumpscare_effect:
		jumpscare_effect.flash_screen()
	
	# Get player camera
	var player_camera = player.get_node("%PlayerCam")
	if not player_camera:
		print("ERROR: Player camera not found!")
		return
	
	# Create jumpscare sound
	var jumpscare_sound = AudioStreamPlayer.new()
	add_child(jumpscare_sound)
	if ResourceLoader.exists("res://assets/audio/jumpscare_sound.wav"):
		jumpscare_sound.stream = load("res://assets/audio/jumpscare_sound.wav")
		jumpscare_sound.play()
	
	# Make a duplicate of the enemy model for jumpscare
	var jumpscare_model = enemy.duplicate()
	jumpscare_model.set_script(null)  # Remove the script
	
	# Remove unnecessary nodes
	for child in jumpscare_model.get_children():
		if child is Area3D or child is CollisionShape3D:
			child.queue_free()
	
	# Add to camera
	player_camera.add_child(jumpscare_model)
	
	# Position in front of camera
	jumpscare_model.global_transform = Transform3D()
	jumpscare_model.position = Vector3(0, 0, -0.5)
	
	# Create violent shake effect
	var tween = create_tween()
	tween.set_loops(20)
	
	for i in range(20):
		var random_offset = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0.3),
			randf_range(-0.3, 0)
		)
		
		# Shake the model rapidly
		tween.tween_property(jumpscare_model, "position", random_offset, 0.03)
		
		# Also apply random rotation
		var random_rotation = Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2), 
			randf_range(-0.2, 0.2)
		)
		tween.tween_property(jumpscare_model, "rotation", random_rotation, 0.03)
	
	# Wait for shake to complete
	await tween.finished
	
	# Free the jumpscare model
	jumpscare_model.queue_free()
	
	# Let the enemy continue with its jumpscare sequence
	enemy.do_jumpscare_sequence()

func _input(event):
	# Skip input processing if a jumpscare is in progress
	if is_jumpscare_active:
		return
		
	if event.is_action_pressed("cancel"):
		# Toggle pause
		if pause_menu.visible:
			pause_menu.hide()
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			pause_menu.show()
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
