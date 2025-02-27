# SimpleDoor.gd
extends StaticBody3D

@export var locked: bool = false
@export var requires_keycard: bool = false
@export var door_id: String = "door_1"
@export var auto_close_time: float = 5.0  # Set to 0 to disable auto-close
@export var open_angle: float = 90.0  # Degrees the door opens
@export var reverse_rotation: bool = false  # Flip rotation direction

var is_open: bool = false
var player_nearby: bool = false
var interaction_distance: float = 2.0

func _ready():
	add_to_group("doors")
	
	# Create interaction area if not present
	if not has_node("InteractionArea"):
		var area = Area3D.new()
		area.name = "InteractionArea"
		add_child(area)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_shape.shape = BoxShape3D.new()
		collision_shape.shape.size = Vector3(3, 2, 3)  # Adjust as needed
		area.add_child(collision_shape)
	
	# Connect signals
	if has_node("InteractionArea"):
		var area = get_node("InteractionArea")
		if not area.is_connected("body_entered", Callable(self, "_on_interaction_area_body_entered")):
			area.body_entered.connect(Callable(self, "_on_interaction_area_body_entered"))
		
		if not area.is_connected("body_exited", Callable(self, "_on_interaction_area_body_exited")):
			area.body_exited.connect(Callable(self, "_on_interaction_area_body_exited"))

func _process(_delta):
	if player_nearby and Input.is_action_just_pressed("interact"):
		toggle_door()

func toggle_door():
	if is_open:
		close_door()
	else:
		open_door()

func open_door():
	if locked:
		var game_state = get_node_or_null("/root/Main/GameState")
		var has_keycard = game_state and game_state.has_keycard
		
		if requires_keycard and not has_keycard:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").show_prompt("This door requires a keycard")
			return
		else:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").show_prompt("This door is locked")
			return
	
	is_open = true
	
	# Disable collision while door is open
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = true
	
	# Rotate the door along its hinge
	var target_angle = deg_to_rad(open_angle)
	if reverse_rotation:
		target_angle = -target_angle
		
	var tween = create_tween()
	tween.tween_property($DoorPivot, "rotation:y", target_angle, 0.5)
	
	# Auto-close timer
	if auto_close_time > 0:
		await get_tree().create_timer(auto_close_time).timeout
		if is_open:  # Check if it's still open
			close_door()

func close_door():
	is_open = false
	
	# Simple door position change (no animation)
	var tween = create_tween()
	tween.tween_property($DoorPivot, "rotation:y", 0.0, 0.5)
	
	# Re-enable collision
	await tween.finished
	if has_node("CollisionShape3D"):
		$CollisionShape3D.disabled = false

func _on_interaction_area_body_entered(body):
	if body.name == "Player" or body.name == "%Player" or body.get_path().get_name(body.get_path().get_name_count() - 1) == "Player":
		player_nearby = true
		if get_node_or_null("/root/Main/InteractionPrompt"):
			if not locked:
				get_node("/root/Main/InteractionPrompt").show_prompt("Press E to " + ("close" if is_open else "open") + " door")
			else:
				if requires_keycard:
					get_node("/root/Main/InteractionPrompt").show_prompt("Locked - requires keycard")
				else:
					get_node("/root/Main/InteractionPrompt").show_prompt("This door is locked")

func _on_interaction_area_body_exited(body):
	if body.name == "Player" or body.name == "%Player" or body.get_path().get_name(body.get_path().get_name_count() - 1) == "Player":
		player_nearby = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()

func unlock():
	locked = false
	if player_nearby and get_node_or_null("/root/Main/InteractionPrompt"):
		get_node("/root/Main/InteractionPrompt").show_prompt("Press E to open door")
