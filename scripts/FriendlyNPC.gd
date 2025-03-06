extends CharacterBody3D

@export var npc_id: String = "robot1"
@export var npc_name: String = "Robot"
@export var interaction_distance: float = 3.0
@export var face_player_during_dialogue: bool = true

var is_hostile: bool = false
var can_interact: bool = false
var player = null
var in_dialogue = false
var original_rotation = Vector3.ZERO

func _ready():
	add_to_group("npcs")
	print("FriendlyNPC ready: " + npc_name + " (ID: " + npc_id + ")")
	
	# Store original rotation
	original_rotation = rotation
	
	# Create interaction area if not present
	if not has_node("InteractionArea"):
		var area = Area3D.new()
		area.name = "InteractionArea"
		add_child(area)
		
		var collision_shape = CollisionShape3D.new()
		collision_shape.name = "CollisionShape3D"
		collision_shape.shape = SphereShape3D.new()
		collision_shape.shape.radius = interaction_distance
		area.add_child(collision_shape)
		
		area.body_entered.connect(Callable(self, "_on_area_entered"))
		area.body_exited.connect(Callable(self, "_on_area_exited"))
	
	# Connect to dialogue signals if DialogueManager exists
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(Callable(self, "_on_dialogue_started"))
		dialogue_manager.dialogue_ended.connect(Callable(self, "_on_dialogue_ended"))

func _process(_delta):
	if can_interact and player and not is_hostile and not in_dialogue:
		var distance = global_position.distance_to(player.global_position)
		if distance <= interaction_distance:
			var interaction_prompt = get_node_or_null("/root/Main/UI/InteractionPrompt")
			if interaction_prompt:
				interaction_prompt.show_prompt("Press E to talk to " + npc_name)
			
			if Input.is_action_just_pressed("interact"):
				start_dialogue()
		else:
			var interaction_prompt = get_node_or_null("/root/Main/UI/InteractionPrompt")
			if interaction_prompt:
				interaction_prompt.hide_prompt()
	
	# Face player during dialogue if enabled
	if in_dialogue and face_player_during_dialogue and player:
		var direction = player.global_position - global_position
		direction.y = 0  # Keep on horizontal plane
		
		if direction.length() > 0.01:
			var target_rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
			rotation = target_rotation

func _on_area_entered(body):
	if is_player(body):
		print(npc_name + ": Player detected in interaction area")
		can_interact = true
		player = body

func _on_area_exited(body):
	if is_player(body):
		print(npc_name + ": Player left interaction area")
		can_interact = false
		var interaction_prompt = get_node_or_null("/root/Main/UI/InteractionPrompt")
		if interaction_prompt:
			interaction_prompt.hide_prompt()

func is_player(body):
	return body.name == "Player" or body.name == "%Player"

func start_dialogue():
	if is_hostile:
		return
	
	print(npc_name + ": Starting dialogue")
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.start_dialogue(npc_id, npc_name)
	else:
		print("ERROR: DialogueManager not found!")
	
func _on_dialogue_started(talking_to_npc):
	# Only react if this is the NPC being talked to
	if talking_to_npc == npc_name or (dialogue_manager_has_npc_name() and talking_to_npc == dialogue_manager_get_npc_name()):
		in_dialogue = true
		
		# If we're set to face the player, make sure we're doing that now
		if face_player_during_dialogue and player:
			var direction = player.global_position - global_position
			direction.y = 0  # Keep on horizontal plane
			
			if direction.length() > 0.01:
				var target_rotation = Vector3(0, atan2(-direction.x, -direction.z), 0)
				
				# Create a smooth tween for the rotation
				var tween = create_tween()
				tween.tween_property(self, "rotation", target_rotation, 0.3)

func _on_dialogue_ended():
	if in_dialogue:
		in_dialogue = false
		
		# Return to original orientation if we were facing the player
		if face_player_during_dialogue:
			var tween = create_tween()
			tween.tween_property(self, "rotation", original_rotation, 0.5)

func dialogue_manager_has_npc_name():
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return false
		
	if not dialogue_manager.dialogue_data.has(npc_id):
		return false
		
	return dialogue_manager.dialogue_data[npc_id].has("name")

func dialogue_manager_get_npc_name():
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if not dialogue_manager:
		return npc_name
		
	if not dialogue_manager.dialogue_data.has(npc_id):
		return npc_name
		
	if not dialogue_manager.dialogue_data[npc_id].has("name"):
		return npc_name
		
	return dialogue_manager.dialogue_data[npc_id]["name"]
	
func become_hostile():
	is_hostile = true
	can_interact = false
	in_dialogue = false
	print(npc_name + " is now hostile!")
	
	# Change to enemy AI
	if ResourceLoader.exists("res://scripts/EnemyAI.gd"):
		set_script(load("res://scripts/EnemyAI.gd"))
		# Initialize enemy AI
		_ready()
	elif ResourceLoader.exists("res://scripts/enemyai.gd"):
		set_script(load("res://scripts/enemyai.gd"))
		# Initialize enemy AI
		_ready()
	else:
		# Fallback if script not found
		print("WARNING: EnemyAI.gd not found, using basic hostile behavior")
		# Basic hostile behavior without animation
