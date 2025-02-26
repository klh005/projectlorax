extends CharacterBody3D

@onready var interaction_label = $"../NoteUI/InteractionLabel"
@onready var comp_interaction_label = $"../CompUI/InteractionLabel"
@onready var note_ui = $"../NoteUI"  # Make sure the path is correct
@onready var raycast = $RayCast3D
@onready var interaction_label = $"../UI/NoteUI/InteractionLabel"
@onready var note_ui = $"../UI/NoteUI"  # Make sure the path is correct
var current_note = null  # Stores the note the player is looking at
var looking_note = false
var looking_comp = false
var comp_status = null

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

# Camera reference
@onready var head := $Camera3D
@onready var raycast = $Camera3D2/RayCast3D

@onready var head := %PlayerCam

signal made_sound(player_position: Vector3)

var current_speed := move_speed
var fall_velocity := 0.0
var camera_x_rotation := 0.0
var head_bob_offset := Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize camera position
	head.position.z = camera_forward_offset
	head.position.y = camera_height  # Set initial camera height

func _input(event):
	if event is InputEventMouseMotion:
		# Horizontal rotation (player body)
		rotate_y(deg_to_rad(-event.relative.x * horizontal_sensitivity))
		
		# Vertical rotation (camera only)
		camera_x_rotation -= event.relative.y * vertical_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, vertical_clamp_min, vertical_clamp_max)
		
		# Apply vertical rotation to camera
		head.rotation_degrees.x = camera_x_rotation
		
	# Open and close note UI
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		print("Pressed E!")
		if current_note:
			print("current note exists")
			if current_note.is_open:
				#print("Closing note...")
				current_note.close_note()
				current_note = null
			else:
				#print("Opening note...")
				current_note.open_note()
		elif comp_status:
			print("Comp detected")
			if comp_status.is_open:
				#print("Closing computer...")
				comp_status.close_comp()
				comp_status = null
			else:
				#print("Opening computer...")
				comp_status.open_comp()
		

func _physics_process(delta):
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

func _process(delta):
	# Ensure RayCast3D always follows the camera's direction
	raycast.global_transform = head.global_transform
	
	if raycast.is_colliding():
		var hit_object = raycast.get_collider()
		#print("Raycast is colliding with:", hit_object.name)
		if hit_object is Area3D and hit_object.has_method("on_looked_at") and !hit_object.is_open:
			hit_object.on_looked_at()
			current_note = hit_object
			looking_note = true
			return
		if hit_object is Area3D and hit_object.has_method("look_comp") and !hit_object.is_open:
			hit_object.look_comp()
			comp_status = hit_object
			looking_comp = true
			return
			
	comp_interaction_label.visible = false
	interaction_label.visible = false
	#looking_note = false
	#looking_comp = false
	current_object = null
	
@export var sound_threshold: float = 2.0  # Minimum speed to make sound
@export var running_sound_multiplier: float = 2.0  # Increase sound when running

# Existing is_making_sound() function - replace with this improved version
func is_making_sound() -> bool:
	# Calculate horizontal velocity (ignoring vertical/falling movement)
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	
	# Check if the player is running
	var is_running = Input.is_action_pressed("run")
	
	# Make more noise when running
	var effective_speed = horizontal_speed
	if is_running:
		effective_speed *= running_sound_multiplier
	
	# Only emit sound if above threshold
	var making_sound = effective_speed > sound_threshold
	
	# Optionally emit the signal with current position (if you want to keep this behavior)
	if making_sound:
		emit_signal("made_sound", global_position)
		
	return making_sound

# Add this function to allow manual sound emission (for testing or other triggers)
func make_noise(multiplier: float = 1.0) -> void:
	emit_signal("made_sound", global_position)
	
	# You could visualize this with a debug sphere or message
	print("Player made deliberate noise!")
