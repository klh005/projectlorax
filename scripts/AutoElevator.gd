# AutoElevator.gd
extends Node3D

# Configure these based on your GridMap cell size
@export var grid_cell_size: float = 1.0 
@export var floors_height_in_cells: int = 10  # How many grid cells tall is each floor

# Floor configuration
@export var floors: Array[int] = [1, 2, 3]  # Floor numbers for display
@export var auto_cycle: bool = true         # Whether elevator should cycle automatically
@export var wait_time: float = 5.0          # How long to wait at each floor

# Elevator settings
@export var movement_speed: float = 5.0

# Current state
var current_floor_index: int = 0
var target_floor_index: int = 0
var is_moving: bool = false
var player_inside: bool = false
var wait_timer: float = 0.0

# Node references
@onready var elevator_cabin = $ElevatorCabin
@onready var floor_display = $ElevatorCabin/FloorDisplay
@onready var door = $ElevatorCabin/Door
@onready var interior_area = $ElevatorCabin/InteriorArea

func _ready():
	# Position at starting floor
	elevator_cabin.position.y = current_floor_index * floors_height_in_cells * grid_cell_size
	#update_floor_display()
	
	# Connect area signals
	if interior_area:
		interior_area.body_entered.connect(Callable(self, "_on_interior_area_body_entered"))
		interior_area.body_exited.connect(Callable(self, "_on_interior_area_body_exited"))
	
	# Start with door open
	open_door()
	
	# Start wait timer
	wait_timer = wait_time

func _process(delta):
	if is_moving:
		move_elevator(delta)
	elif auto_cycle:
		# Handle automatic movement
		wait_timer -= delta
		if wait_timer <= 0:
			go_to_next_floor()

func move_elevator(delta):
	var target_y = target_floor_index * floors_height_in_cells * grid_cell_size
	var current_y = elevator_cabin.position.y
	
	if abs(current_y - target_y) < 0.05:
		# Arrived at target floor
		elevator_cabin.position.y = target_y
		is_moving = false
		current_floor_index = target_floor_index
		#update_floor_display()
		open_door()
		
		# Reset wait timer
		wait_timer = wait_time
		
		# Play elevator arrival sound if available
		if has_node("ElevatorCabin/ArrivalSound") and $ElevatorCabin/ArrivalSound is AudioStreamPlayer3D:
			$ElevatorCabin/ArrivalSound.play()
	else:
		# Move towards target floor
		var direction = 1 if target_y > current_y else -1
		elevator_cabin.position.y += direction * movement_speed * delta
		
		# Update display during movement
		var current_progress = floor((elevator_cabin.position.y / grid_cell_size) / floors_height_in_cells)
		#if current_progress >= 0 and current_progress < floors.size():
			#floor_display.text = str(floors[current_progress])

func go_to_next_floor():
	if is_moving:
		return
		
	# Go to the next floor in sequence
	target_floor_index = (current_floor_index + 1) % floors.size()
	
	# Show a message to player if they're inside
	if player_inside and get_node_or_null("/root/Main/InteractionPrompt"):
		get_node("/root/Main/InteractionPrompt").show_prompt("Elevator moving to floor: " + str(floors[target_floor_index]))
	
	close_door()
	
	# Play elevator moving sound if available
	if has_node("ElevatorCabin/MovingSound") and $ElevatorCabin/MovingSound is AudioStreamPlayer3D:
		$ElevatorCabin/MovingSound.play()
	
	# Small delay before movement starts (simulating door closing)
	await get_tree().create_timer(1.0).timeout
	
	# Start elevator movement
	is_moving = true

func open_door():
	# Simulate door opening
	if door:
		var tween = create_tween()
		tween.tween_property(door, "position:x", grid_cell_size, 0.5)  # Move door to open position
		
		# Play door sound if available
		if has_node("ElevatorCabin/DoorSound") and $ElevatorCabin/DoorSound is AudioStreamPlayer3D:
			$ElevatorCabin/DoorSound.play()

func close_door():
	# Simulate door closing
	if door:
		var tween = create_tween()
		tween.tween_property(door, "position:x", 0, 0.5)  # Move door to closed position
		
		# Play door sound if available
		if has_node("ElevatorCabin/DoorSound") and $ElevatorCabin/DoorSound is AudioStreamPlayer3D:
			$ElevatorCabin/DoorSound.play()

#func update_floor_display():
	#if floor_display:
		#floor_display.text = str(floors[current_floor_index])

func _on_interior_area_body_entered(body):
	if body.name == "Player" or body.name == "%Player" or body.get_path().get_name(body.get_path().get_name_count() - 1) == "Player":
		player_inside = true
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").show_prompt("Automatic elevator - next stop: floor " + str(floors[(current_floor_index + 1) % floors.size()]))

func _on_interior_area_body_exited(body):
	if body.name == "Player" or body.name == "%Player" or body.get_path().get_name(body.get_path().get_name_count() - 1) == "Player":
		player_inside = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()
