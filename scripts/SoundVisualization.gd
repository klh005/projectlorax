# EmergencyShutdownLever.gd
extends Node3D

@export var lever_id: String = "factory_shutdown_lever"
@export var requires_keycard: bool = false
@export var confirmation_dialog: bool = true

var player_nearby: bool = false
var lever_pulled: bool = false
var is_sequence_playing: bool = false

# References for animation/effects
@onready var lever_mesh = $LeverMesh if has_node("LeverMesh") else null
@onready var control_panel = $ControlPanel if has_node("ControlPanel") else null

# Sounds
@onready var alarm_sound = $AlarmSound if has_node("AlarmSound") else null
@onready var lever_sound = $LeverSound if has_node("LeverSound") else null

func _ready():
	add_to_group("interactive_objects")
	
	# Create interaction area if not present
	if not has_node("InteractionArea"):
		var area = Area3D.new()
		area.name = "InteractionArea"
		add_child(area)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D" 
		collision_shape.shape = SphereShape3D.new()
		collision_shape.shape.radius = 2.0  # Interaction radius
		area.add_child(collision_shape)
		
		area.body_entered.connect(Callable(self, "_on_interaction_area_body_entered"))
		area.body_exited.connect(Callable(self, "_on_interaction_area_body_exited"))

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact") and not lever_pulled and not is_sequence_playing:
		pull_lever()

func pull_lever():
	if lever_pulled or is_sequence_playing:
		return
		
	if requires_keycard:
		var game_state = get_node_or_null("/root/Main/GameState")
		var has_keycard = game_state and game_state.has_keycard
		
		if not has_keycard:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").show_prompt("This lever requires a keycard")
			return
	
	if confirmation_dialog and get_node_or_null("/root/Main/ConfirmationDialog"):
		# Show confirmation dialog
		get_node("/root/Main/ConfirmationDialog").show_dialog(
			"WARNING: Factory emergency shutdown will disrupt all robotic systems. Are you sure?",
			Callable(self, "_on_confirm_lever_pull")
		)
	else:
		_on_confirm_lever_pull()

func _on_confirm_lever_pull():
	lever_pulled = true
	is_sequence_playing = true
	
	# Hide interaction prompt
	if get_node_or_null("/root/Main/InteractionPrompt"):
		get_node("/root/Main/InteractionPrompt").hide_prompt()
	
	# Play lever pull sound if available
	if lever_sound:
		lever_sound.play()
	
	# Animate lever movement (simple tween animation)
	if lever_mesh:
		var tween = create_tween()
		tween.tween_property(lever_mesh, "rotation:x", -PI/4, 0.5)  # Pull lever down
	
	# Show "Shutting down..." message
	if get_node_or_null("/root/Main/NotificationSystem"):
		get_node("/root/Main/NotificationSystem").show_notification("FACTORY SHUTDOWN SEQUENCE INITIATED", 3.0)
	
	# Wait briefly before the shutdown "fails"
	await get_tree().create_timer(3.0).timeout
	
	# Control panel flickers if it exists
	if control_panel:
		var panel_tween = create_tween()
		for i in range(5):
			panel_tween.tween_property(control_panel, "visible", false, 0.2)
			panel_tween.tween_property(control_panel, "visible", true, 0.2)
	
	# Play alarm if available
	if alarm_sound:
		alarm_sound.play()
	
	# Show error message
	if get_node_or_null("/root/Main/NotificationSystem"):
		get_node("/root/Main/NotificationSystem").show_notification("ERROR: SHUTDOWN OVERRIDE DETECTED", 2.0)
		await get_tree().create_timer(2.0).timeout
		get_node("/root/Main/NotificationSystem").show_notification("WARNING: ROBOTIC SYSTEMS ENTERING DEFENSE MODE", 3.0)
	
	# Flicker lights if any are available
	flicker_lights()
	
	# Wait a moment for dramatic effect
	await get_tree().create_timer(2.0).timeout
	
	# Start the actual game - robots become hostile
	if get_node_or_null("/root/Main/GameState"):
		get_node("/root/Main/GameState").start_game()
	
	is_sequence_playing = false

func flicker_lights():
	# Find lights in the scene and flicker them
	var lights = get_tree().get_nodes_in_group("main_lights")
	if lights.size() > 0:
		var light_tween = create_tween()
		for i in range(5):
			for light in lights:
				if light is Light3D:
					light_tween.tween_property(light, "visible", false, 0.1)
			light_tween.tween_interval(0.1)
			for light in lights:
				if light is Light3D:
					light_tween.tween_property(light, "visible", true, 0.1)
			light_tween.tween_interval(0.3)
		
		# Finally turn off main lights and turn on emergency lights
		for light in lights:
			if light is Light3D:
				light.visible = false
		
		for emergency_light in get_tree().get_nodes_in_group("emergency_lights"):
			if emergency_light is Light3D:
				emergency_light.visible = true

func _on_interaction_area_body_entered(body):
	if body.name == "Player":
		player_nearby = true
		if not lever_pulled and not is_sequence_playing:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").show_prompt("Press E to pull emergency shutdown lever")

func _on_interaction_area_body_exited(body):
	if body.name == "Player":
		player_nearby = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()

func reset() -> void:
	# Reset state when starting a new game
	lever_pulled = false
	is_sequence_playing = false
	
	# Reset lever position if mesh exists
	if lever_mesh:
		lever_mesh.rotation.x = 0
