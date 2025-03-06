extends Node3D

# UI Components
@onready var note_ui = $UI/NoteUI
@onready var pause_menu = $UI/PauseMenu
@onready var jumpscare_effect = $UI/JumpscareEffect
@onready var dialogue_ui = $UI/DialogueUI
@onready var notification_system = $UI/NotificationSystem
@onready var confirmation_dialog = $UI/ConfirmationDialog
@onready var interaction_prompt = $UI/InteractionPrompt
@onready var comp_ui = $UI/CompUI

var is_jumpscare_active = false
var ui_paused = false

func _ready():
	print("Main scene starting")
	
	# Reset game state when starting a new game
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.has_method("reset"):
		game_state.reset()
	
	# Unpause and ensure game is ready to play
	get_tree().paused = false
	
	# Ensure all UI components are initialized correctly
	setup_ui_components()
	
	# Connect notes to NoteUI
	connect_notes_to_ui()
	
	# Setup NPCs and Enemies
	setup_npcs()
	
	# Setup computers
	setup_computers()
	
	print("Main scene initialization complete")

func setup_ui_components():
	# Make sure UI nodes are properly initialized
	if !note_ui:
		note_ui = get_node_or_null("UI/NoteUI")
	
	if !pause_menu:
		pause_menu = get_node_or_null("UI/PauseMenu")
	
	if !jumpscare_effect:
		jumpscare_effect = get_node_or_null("UI/JumpscareEffect")
	
	if !dialogue_ui:
		dialogue_ui = get_node_or_null("UI/DialogueUI")
	
	if !notification_system:
		notification_system = get_node_or_null("UI/NotificationSystem")
	
	if !confirmation_dialog:
		confirmation_dialog = get_node_or_null("UI/ConfirmationDialog")
	
	if !interaction_prompt:
		interaction_prompt = get_node_or_null("UI/InteractionPrompt")
	
	if !comp_ui:
		comp_ui = get_node_or_null("UI/CompUI")
	
	# Ensure pause menu has the correct initial state
	if pause_menu:
		pause_menu.visible = false

func connect_notes_to_ui():
	if !note_ui:
		print("Warning: NoteUI not found")
		return
		
	# Connect notes to NoteUI
	for note in get_tree().get_nodes_in_group("notes"):
		print("Connecting note: ", note.name)
		
		# Remove any existing connections to avoid duplicates
		if note.is_connected("note_opened", Callable(note_ui, "show_note")):
			note.disconnect("note_opened", Callable(note_ui, "show_note"))
			
		if note.is_connected("note_closed", Callable(note_ui, "hide_note")):
			note.disconnect("note_closed", Callable(note_ui, "hide_note"))
		
		# Add new connections
		note.note_opened.connect(Callable(note_ui, "show_note"))
		note.note_closed.connect(Callable(note_ui, "hide_note"))

func setup_computers():
	# Find all computers in the scene
	var computers = []
	
	# Direct child computers
	var direct_comp = get_node_or_null("Computer")
	if direct_comp:
		computers.append(direct_comp)
	
	# Child computers in GridMap
	var grid_map = get_node_or_null("GridMap")
	if grid_map:
		for child in grid_map.get_children():
			if child.get_script() and "computer.gd" in child.get_script().resource_path:
				computers.append(child)
	
	# Connect all computers to UI
	for comp in computers:
		print("Setting up computer: ", comp.name)
		
		# Remove any existing connections to avoid duplicates
		if comp.is_connected("comp_opened", Callable(comp_ui, "show_comp")):
			comp.disconnect("comp_opened", Callable(comp_ui, "show_comp"))
			
		if comp.is_connected("comp_closed", Callable(comp_ui, "hide_comp")):
			comp.disconnect("comp_closed", Callable(comp_ui, "hide_comp"))
		
		# Add new connections
		comp.comp_opened.connect(Callable(comp_ui, "show_comp"))
		comp.comp_closed.connect(Callable(comp_ui, "hide_comp"))

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

func _input(event):
	# Skip input processing if a jumpscare is in progress
	if is_jumpscare_active:
		return
	
	# Handle ESC key for pause menu
	if event.is_action_pressed("cancel"):
		# If dialogue is active, end it
		var dialogue_manager = get_node_or_null("/root/DialogueManager")
		if dialogue_manager and dialogue_manager.is_dialogue_active:
			dialogue_manager.end_dialogue()
			return
			
		# If note or computer UI is active, close it
		if note_ui and note_ui.is_visible:
			# Find the note and close it
			for note in get_tree().get_nodes_in_group("notes"):
				if note.is_open:
					note.close_note()
					return
		
		if comp_ui and comp_ui.is_visible:
			# Find open computers and close them
			var computers = get_tree().get_nodes_in_group("computers")
			for comp in computers:
				if comp.is_open:
					comp.close_comp()
					return
		
		# Otherwise toggle pause menu
		toggle_pause_menu()

func toggle_pause_menu():
	if !pause_menu:
		return
		
	if pause_menu.visible:
		pause_menu.hide_pm()
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		ui_paused = false
		
		# Ensure player can move again
		var player = get_node_or_null("%Player")
		if !player:
			player = get_node_or_null("Player")
		if player and player.has_method("set_ui_paused"):
			player.set_ui_paused(false)
	else:
		pause_menu.show_pm()
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		ui_paused = true
		
		# Ensure player doesn't move when paused
		var player = get_node_or_null("%Player")
		if !player:
			player = get_node_or_null("Player")
		if player and player.has_method("set_ui_paused"):
			player.set_ui_paused(true)
			
# Function to handle jumpscare effect
func create_jumpscare_effect(enemy):
	if is_jumpscare_active:
		return
	
	is_jumpscare_active = true
	
	# Get the player
	var player = get_node_or_null("%Player")
	if not player:
		player = get_node_or_null("Player")
		if not player:
			print("ERROR: Player node not found!")
			is_jumpscare_active = false
			return
	
	# Pause player input
	player.set_ui_paused(true)
	
	# Flash screen effect
	if jumpscare_effect:
		jumpscare_effect.flash_screen()
	
	# Get player camera
	var player_camera = player.get_node_or_null("%PlayerCam")
	if not player_camera:
		player_camera = player.get_node_or_null("PlayerCam")
		if not player_camera:
			print("ERROR: Player camera not found!")
			is_jumpscare_active = false
			player.set_ui_paused(false)
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
	
	# Create shake effect
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
	jumpscare_sound.queue_free()
	jumpscare_model.queue_free()
	
	# Reset jumpscare state
	is_jumpscare_active = false
	
	# Resume player after a delay
	await get_tree().create_timer(0.5).timeout
	player.set_ui_paused(false)
