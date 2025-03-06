extends CharacterBody3D

@onready var interaction_label = null
@onready var comp_interaction_label = null
@onready var note_ui = null
@onready var comp_ui = null
@onready var raycast = null
@onready var head = null

var current_note = null  # Stores the note the player is looking at
var current_comp = null  # Stores the computer the player is looking at
var looking_at_interactable = false

# Movement parameters
@export var move_speed := 7.0
@export var run_multiplier := 1.8
@export var gravity := 28.0
@export var air_accel := 14.0

@export var jump_force := 10.0  # Vertical jump strength
@export var air_control := 0.5  # Air movement multiplier

# Camera parameters
@export var camera_forward_offset := -0.2  # Z-axis displacement from player center
@export var camera_height := 1.6  # Fixed camera height
@export var vertical_clamp_min := -90.0
@export var vertical_clamp_max := 90.0
@export var horizontal_sensitivity := 0.1
@export var vertical_sensitivity := 0.08

# Head bob parameters
@export var head_bob_intensity := 0.02  # Reduced intensity for smaller head bob
@export var head_bob_speed := 10.0

signal made_sound(player_position: Vector3)

var current_speed := move_speed
var fall_velocity := 0.0
var camera_x_rotation := 0.0
var head_bob_offset := Vector3.ZERO
var ui_paused := false  # Track if we're interacting with UI

func _ready():
	# Find UI components more reliably by searching the scene tree
	var main = get_tree().get_current_scene()
	
	if main.has_node("UI/NoteUI/InteractionLabel"):
		interaction_label = main.get_node("UI/NoteUI/InteractionLabel")
	
	if main.has_node("UI/CompUI/InteractionLabel"):
		comp_interaction_label = main.get_node("UI/CompUI/InteractionLabel")
	
	if main.has_node("UI/NoteUI"):
		note_ui = main.get_node("UI/NoteUI")
	
	if main.has_node("UI/CompUI"):
		comp_ui = main.get_node("UI/CompUI")
	
	raycast = $RayCast3D
	if !raycast:
		# If not found, try to find it elsewhere
		raycast = get_node_or_null("../Player/RayCast3D")
	
	head = %PlayerCam
	if !head:
		head = get_node_or_null("Camera3D")  # Fallback
	
	# Set initial mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Initialize camera position if head exists
	if head:
		head.position.z = camera_forward_offset
		head.position.y = camera_height

func _input(event):
	# Skip input processing if we're paused or a dialog is open
	if ui_paused:
		return
	
	# Handle camera movement with mouse
	if event is InputEventMouseMotion:
		# Horizontal rotation (player body)
		rotate_y(deg_to_rad(-event.relative.x * horizontal_sensitivity))
		
		# Vertical rotation (camera only)
		camera_x_rotation -= event.relative.y * vertical_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, vertical_clamp_min, vertical_clamp_max)
		
		# Apply vertical rotation to camera
		if head:
			head.rotation_degrees.x = camera_x_rotation
	
	# Interaction key
	if event.is_action_pressed("interact"):
		handle_interaction()

func handle_interaction():
	print("Handling interaction...")
	
	# Handle note interaction
	if current_note:
		print("Interacting with note")
		if current_note.has_method("open_note") and not current_note.is_open:
			var text = ""
			if current_note.has_node("RichTextLabel"):
				text = current_note.get_node("RichTextLabel").text
			current_note.open_note(text)
			ui_paused = true
		elif current_note.has_method("close_note"):
			current_note.close_note()
			current_note = null
			ui_paused = false
	
	# Handle computer interaction
	elif current_comp:
		print("Interacting with computer")
		if current_comp.has_method("open_comp") and not current_comp.is_open:
			current_comp.open_comp()
			ui_paused = true
		elif current_comp.has_method("close_comp"):
			current_comp.close_comp()
			current_comp = null
			ui_paused = false

func _physics_process(delta):
	if ui_paused:
		# Don't process movement when interacting with UI
		return
		
	handle_movement(delta)
	apply_head_bob(delta)
	
	if is_on_floor() and is_making_sound():
		emit_signal("made_sound", global_position)

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		fall_velocity = -0.01
		current_speed = move_speed * (run_multiplier if Input.is_action_pressed("run") else 1.0)
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# Jumping
		if Input.is_action_just_pressed("jump"):
			fall_velocity = jump_force
			velocity.y = fall_velocity
	else:
		# Air control with reduced movement
		var air_dir = direction * air_accel * air_control * delta
		velocity.x += air_dir.x
		velocity.z += air_dir.z
		
		# Apply gravity
		fall_velocity -= gravity * delta
		velocity.y = fall_velocity

	move_and_slide()

func apply_head_bob(delta):
	if !head:
		return
		
	if is_on_floor() and velocity.length() > 1.0:
		var bob_offset = Vector3(
			sin(Time.get_ticks_msec() * 0.001 * head_bob_speed) * head_bob_intensity,
			cos(Time.get_ticks_msec() * 0.001 * head_bob_speed * 2) * head_bob_intensity,
			0
		)
		head_bob_offset = head_bob_offset.lerp(bob_offset, delta * 8.0)
	else:
		head_bob_offset = head_bob_offset.lerp(Vector3.ZERO, delta * 8.0)

	# Apply offsets while maintaining camera displacement
	head.position = Vector3(
		head_bob_offset.x,
		camera_height + head_bob_offset.y,  # Maintain fixed camera height
		camera_forward_offset  # Use exported displacement value
	)

func _process(_delta):
	if ui_paused:
		return
		
	if !raycast or !head:
		return
		
	# Ensure RayCast3D always follows the camera's direction
	raycast.global_transform = head.global_transform
	
	# Reset interaction state
	looking_at_interactable = false
	
	# Check for interactable objects
	if raycast.is_colliding():
		var hit_object = raycast.get_collider()
		
		# Handle note objects
		if hit_object is Area3D and hit_object.has_method("on_looked_at"):
			if hit_object.has_method("is_open") and not hit_object.is_open:
				hit_object.on_looked_at()
				current_note = hit_object
				current_comp = null
				looking_at_interactable = true
			elif !hit_object.has_method("is_open"):
				hit_object.on_looked_at()
				current_note = hit_object
				current_comp = null
				looking_at_interactable = true
		
		# Handle computer objects
		elif hit_object is Area3D and hit_object.has_method("look_comp"):
			if hit_object.has_method("is_open") and not hit_object.is_open:
				hit_object.look_comp()
				current_comp = hit_object
				current_note = null
				looking_at_interactable = true
			elif !hit_object.has_method("is_open"):
				hit_object.look_comp()
				current_comp = hit_object
				current_note = null
				looking_at_interactable = true
	
	# Hide interaction prompts if not looking at anything
	if !looking_at_interactable:
		if interaction_label:
			interaction_label.visible = false
		if comp_interaction_label:
			comp_interaction_label.visible = false
		current_note = null
		current_comp = null

# Function to check if player is making sound
func is_making_sound() -> bool:
	# Calculate horizontal velocity (ignoring vertical/falling movement)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	# Check if the player is running
	var is_running = Input.is_action_pressed("run")
	
	# Make more noise when running
	var effective_speed = horizontal_speed
	if is_running:
		effective_speed *= 2.0  # Running sound multiplier
	
	# Only emit sound if above threshold
	var sound_threshold = 2.0  # Minimum speed to make sound
	var making_sound = effective_speed > sound_threshold
	
	return making_sound

# Method to handle UI state change
func set_ui_paused(paused: bool) -> void:
	ui_paused = paused
	if paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
