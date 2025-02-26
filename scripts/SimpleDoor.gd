# SimpleDoor.gd
extends StaticBody3D

@export var locked: bool = false
@export var requires_keycard: bool = false
@export var door_id: String = "door_1"
@export var auto_close_time: float = 5.0  # Set to 0 to disable auto-close

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
		
		area.body_entered.connect(Callable(self, "_on_interaction_area_body_entered"))
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
	
	# Simple door position change (no animation)
	# This rotates the door 90 degrees to open it
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", rotation.y + PI/2, 0.5)
	
	# Disable collision while door is open
	$CollisionShape3D.disabled = true
	
	# Auto-close timer
	if auto_close_time > 0:
		await get_tree().create_timer(auto_close_time).timeout
		if is_open:  # Check if it's still open
			close_door()

func close_door():
	is_open = false
	
	# Simple door position change (no animation)
	var tween = create_tween()
	tween.tween_property(self, "rotation:y", rotation.y - PI/2, 0.5)
	
	# Re-enable collision
	$CollisionShape3D.disabled = false

func _on_interaction_area_body_entered(body):
	if body.name == "Player":
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
	if body.name == "Player":
		player_nearby = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()

func unlock():
	locked = false
	if player_nearby and get_node_or_null("/root/Main/InteractionPrompt"):
		get_node("/root/Main/InteractionPrompt").show_prompt("Press E to open door")
