# FriendlyNPC.gd
extends CharacterBody3D

@export var npc_id: String = "robot1"
@export var npc_name: String = "Robot"
@export var interaction_distance: float = 3.0

var is_hostile: bool = false
var can_interact: bool = false
var player = null

func _ready():
	add_to_group("npcs")
	
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

func _process(_delta):
	if can_interact and player and not is_hostile:
		var distance = global_position.distance_to(player.global_position)
		if distance <= interaction_distance:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").show_prompt("Press E to talk to " + npc_name)
			
			if Input.is_action_just_pressed("interact"):
				start_dialogue()
		else:
			if get_node_or_null("/root/Main/InteractionPrompt"):
				get_node("/root/Main/InteractionPrompt").hide_prompt()

func _on_area_entered(body):
	if body.name == "Player":
		can_interact = true
		player = body

func _on_area_exited(body):
	if body.name == "Player":
		can_interact = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()

func start_dialogue():
	if is_hostile:
		return
		
	if get_node_or_null("/root/Main/DialogueManager"):
		get_node("/root/Main/DialogueManager").start_dialogue(npc_id, npc_name)

func become_hostile():
	is_hostile = true
	can_interact = false
	
	# Change to enemy AI
	if ResourceLoader.exists("res://scripts/EnemyAI.gd"):
		set_script(load("res://scripts/EnemyAI.gd"))
		# Initialize enemy AI
		_ready()
	else:
		# Fallback if script not found
		print("WARNING: EnemyAI.gd not found, using basic hostile behavior")
		# Basic hostile behavior without animation
		# You can implement a simple chase here
