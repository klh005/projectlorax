# EnemyAI.gd
extends CharacterBody3D

# Define AI states.
enum State { PASSIVE, CHASE }
var state: State = State.PASSIVE

# Exported variables for tuning.
@export var chase_speed: float = 6.0
@export var passive_speed: float = 2.0
@export var detection_radius: float = 20.0
@export var patrol_points: Array[Vector3] = []  # Leave empty if not patrolling
var current_patrol_index: int = 0
var original_position: Vector3

# Unique reference to the player node ("Player")
@onready var player: CharacterBody3D = %Player
# Flag to prevent multiple jumpscare triggers
var is_jumpscare_active: bool = false

func _ready() -> void:
	original_position = global_position
	add_to_group("enemies")
	
	# Connect to player's signal if it exists.
	if player:
		player.connect("made_sound", Callable(self, "_on_player_made_sound"))
	
	$SoundDetector.body_entered.connect(Callable(self, "_on_SoundDetector_body_entered"))
	$SoundDetector.body_exited.connect(Callable(self, "_on_SoundDetector_body_exited"))
	
func _physics_process(delta: float) -> void:
	# Skip processing if jumpscare is already triggered
	if is_jumpscare_active:
		return
		
	match state:
		State.PASSIVE:
			_passive_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)

func _passive_behavior(delta: float) -> void:
	if patrol_points.size() > 0:
		var target: Vector3 = patrol_points[current_patrol_index]
		_move_toward(target, passive_speed, delta)
		if global_position.distance_to(target) < 1.0:
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	else:
		# Idle behavior.
		pass

func _chase_behavior(delta: float) -> void:
	_move_toward(player.global_position, chase_speed, delta)
	# When the enemy gets close enough to the player, trigger the jumpscare animation.
	if global_position.distance_to(player.global_position) < 1.5:
		trigger_jumpscare()

func _move_toward(target: Vector3, speed: float, delta: float) -> void:
	var direction: Vector3 = (target - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	
	# Check for direct collision with player
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider == player:
			trigger_jumpscare()
			break

func _on_player_made_sound(player_position: Vector3) -> void:
	if global_position.distance_to(player_position) <= detection_radius:
		state = State.CHASE

func _on_SoundDetector_body_entered(body: Node) -> void:
	if body.name == "Player" and body.has_method("is_making_sound") and body.is_making_sound():
		state = State.CHASE

func _on_SoundDetector_body_exited(body: Node) -> void:
	if body.name == "Player":
		state = State.PASSIVE
		global_position = original_position

func trigger_jumpscare() -> void:
	# Prevent multiple jumpscare triggers
	if is_jumpscare_active:
		return
		
	print("EnemyAI: Starting jumpscare sequence")
	is_jumpscare_active = true
	
	# Freeze player movement and input
	if player:
		player.set_process_input(false)
		player.set_physics_process(false)
		player.velocity = Vector3.ZERO
	
	# Get reference to player's camera
	var player_camera = player.get_node("%PlayerCam")
	
	# Create jumpscare sound if you have one
	var jumpscare_sound = AudioStreamPlayer.new()
	add_child(jumpscare_sound)
	if ResourceLoader.exists("res://assets/audio/jumpscare_sound.wav"):
		jumpscare_sound.stream = load("res://assets/audio/jumpscare_sound.wav")
	else:
		# Create a default sound if file doesn't exist
		var sound = AudioStreamGenerator.new()
		sound.mix_rate = 44100
		jumpscare_sound.stream = sound
	jumpscare_sound.play()
	
	# Make a duplicate of the enemy model for the jumpscare
	var jumpscare_model = duplicate()
	jumpscare_model.set_script(null)  # Remove the AI script from the duplicate
	
	# Remove unnecessary nodes from the duplicate
	for child in jumpscare_model.get_children():
		if child is Area3D or child is CollisionShape3D or child.name == "SoundDetector":
			child.queue_free()
	
	# Add the jumpscare model directly to the camera
	player_camera.add_child(jumpscare_model)
	
	# Position the jumpscare model directly in front of the camera
	jumpscare_model.global_transform = Transform3D()  # Reset transform
	jumpscare_model.position = Vector3(0, -1.5, -0.5)  # Position lower and in front of camera
	
	# Make the model look at the camera
	jumpscare_model.look_at(Vector3(0, 0, 0), Vector3.UP)
	
	# Create a tween for the shaking effect
	var tween = create_tween()
	tween.set_loops(5)  # Shake iterations
	
	# Add violent shaking with random offsets
	for i in range(5):
		var random_offset = Vector3(
			randf_range(-0.3, 0.3),
			randf_range(-1.5, -0.6),  # Keep height position lower
			randf_range(-0.8, -0.3)
		)
		
		# Shake the model rapidly
		tween.tween_property(jumpscare_model, "position", random_offset, 0.05)
		
		# Also apply random rotation for more chaotic effect
		var random_rotation = Vector3(
			randf_range(-0.2, 0.2),
			randf_range(-0.2, 0.2), 
			randf_range(-0.2, 0.2)
		)
		tween.tween_property(jumpscare_model, "rotation", random_rotation, 0.05)
	
	# Wait for the shake to complete - THIS IS CRITICAL FOR TIMING
	await tween.finished
	
	# Free the jumpscare model
	jumpscare_model.queue_free()
	
	# Use a reliable timer for the transition delay
	var timer = get_tree().create_timer(0.5)
	await timer.timeout
	
	print("EnemyAI: Transitioning to game over scene")
	# Directly change the scene (the most reliable approach)
	get_tree().change_scene_to_file("res://scenes/gameover.tscn")

func reset() -> void:
	# Reset all state variables
	state = State.PASSIVE
	is_jumpscare_active = false
	current_patrol_index = 0
	
	# Return to original position
	global_position = original_position
	
	# Reset velocity
	velocity = Vector3.ZERO
