extends Node3D

@onready var note_ui = $UI/NoteUI
@onready var pause_menu: Control = $UI/PauseMenu
@onready var jumpscare_effect = $UI/JumpscareEffect
@onready var dialogue_ui = $UI/DialogueUI
@onready var notification_system = $UI/NotificationSystem
@onready var confirmation_dialog = $UI/ConfirmationDialog
@onready var interaction_prompt = $UI/InteractionPrompt

var is_jumpscare_active = false
var ui_setup = preload("res://scripts/UI_Setup.gd").new()
@onready var comp_ui = $UI/CompUI
@onready var comp = $Computer

func _ready():
	print("Main scene starting")
	
	# Initialize UI elements first
	add_child(ui_setup)
	ui_setup.setup_all_ui_elements()
	
	# Reset game state when starting a new game
	if get_node_or_null("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.has_method("reset"):
			game_state.reset()
	
	# Unpause and ensure game is ready to play
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Connect notes to NoteUI (after UI is set up)
	for note in get_tree().get_nodes_in_group("notes"):
		if note_ui:
			if note.has_signal("note_opened") and note_ui.has_method("show_note"):
				note.note_opened.connect(note_ui.show_note)
			if note.has_signal("note_closed") and note_ui.has_method("hide_note"):
				note.note_closed.connect(note_ui.hide_note)
	
	# Setup NPCs and Enemies
	setup_npcs()
	
	print("Main scene initialization complete")

func setup_npcs():
	# Handle NPCs
	if has_node("NPCs"):
		for robot in $NPCs.get_children():
			setup_robot_for_dialogue(robot, "robot2", "Robot 2")
	
	# Handle Enemies (they can also have dialogue when not hostile)
	if has_node("Enemies"):
		for enemy in $Enemies.get_children():
			setup_robot_for_dialogue(enemy, "robot1", "Robot 1")

func setup_robot_for_dialogue(robot, default_id, default_name):
	print("Setting up dialogue for: " + robot.name)
	
	# Check if the robot already has a script
	var has_friendly_script = false
	var has_enemy_script = false
	
	if robot.get_script() != null:
		var script_path = robot.get_script().resource_path
		has_friendly_script = "FriendlyNPC.gd" in script_path
		has_enemy_script = "enemyai.gd" in script_path or "EnemyAI.gd" in script_path
	
	# Only add FriendlyNPC script if not already assigned one
	if not has_friendly_script and not has_enemy_script:
		print("Adding FriendlyNPC script to " + robot.name)
		robot.set_script(load("res://scripts/FriendlyNPC.gd"))
		
		# Set NPC properties after adding script
		robot.npc_id = default_id
		robot.npc_name = default_name
	elif has_friendly_script:
		# If it already has the FriendlyNPC script, just check/set properties
		if robot.npc_id == "":
			robot.npc_id = default_id
		if robot.npc_name == "":
			robot.npc_name = default_name
	
	# Make sure there's an interaction area
	if not robot.has_node("InteractionArea"):
		print("Adding interaction area to " + robot.name)
		var area = Area3D.new()
		area.name = "InteractionArea"
		robot.add_child(area)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_shape.shape = SphereShape3D.new()
		collision_shape.shape.radius = 3.0
		area.add_child(collision_shape)
		
		# Connect signals if it's a FriendlyNPC
		if has_friendly_script:
			area.body_entered.connect(Callable(robot, "_on_area_entered"))
			area.body_exited.connect(Callable(robot, "_on_area_exited"))
	
	# Add to NPC group if not already
	if not robot.is_in_group("npcs"):
		robot.add_to_group("npcs")

func create_jumpscare_effect(enemy):
	if is_jumpscare_active:
		return
	
	is_jumpscare_active = true
	
	# Get the player
	var player = get_node_or_null("Player")
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
		player_camera = player.get_node_or_null("PlayerCam")
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
	
	# Let the enemy continue with its jumpscare sequence if it has the method
	if enemy.has_method("do_jumpscare_sequence"):
		enemy.do_jumpscare_sequence()

func _input(event):
	# Skip input processing if a jumpscare is in progress
	if is_jumpscare_active:
		return
		
	if event.is_action_pressed("cancel"):
		# If dialogue is active, end it
		if get_node_or_null("/root/DialogueManager") and get_node("/root/DialogueManager").is_dialogue_active:
			get_node("/root/DialogueManager").end_dialogue()
			return
			
		# Otherwise toggle pause menu
		if pause_menu.visible:
			pause_menu.hide()
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			pause_menu.show()
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#print("Found note:", note.name)
		
	comp.comp_opened.connect(comp_ui.show_comp)
	comp.comp_closed.connect(comp_ui.hide_comp)
	#print("All notes connected successfully!")
