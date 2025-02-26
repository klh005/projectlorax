# GridMapElevator.gd
extends Node3D

# Configure these based on your GridMap cell size
@export var grid_cell_size: float = 1.0 
@export var floors_height_in_cells: int = 10  # How many grid cells tall is each floor

# Floor configuration
@export var floors: Array[int] = [1, 2, 3]  # Floor numbers for display

# Elevator settings
@export var movement_speed: float = 5.0
@export var requires_keycard: bool = true

# Current state
var current_floor_index: int = 0
var target_floor_index: int = 0
var is_moving: bool = false
var player_inside: bool = false
var has_keycard: bool = false

# Node references
@onready var elevator_cabin = $ElevatorCabin
@onready var floor_display = $ElevatorCabin/FloorDisplay
@onready var door = $ElevatorCabin/Door
@onready var interior_area = $ElevatorCabin/InteriorArea
@onready var button_panel = $ElevatorCabin/ButtonPanel

func _ready():
	# Position at starting floor
	elevator_cabin.position.y = current_floor_index * floors_height_in_cells * grid_cell_size
	update_floor_display()
	
	# Create buttons if they don't exist
	if button_panel.get_child_count() == 0:
		for i in range(floors.size()):
			var button = Button.new()
			button.text = str(floors[i])
			button.custom_minimum_size = Vector2(30, 30)
			button_panel.add_child(button)
			button.connect("pressed", Callable(self, "_on_floor_button_pressed").bind(i))
	
	# Connect area signals
	if interior_area:
		interior_area.body_entered.connect(Callable(self, "_on_interior_area_body_entered"))
		interior_area.body_exited.connect(Callable(self, "_on_interior_area_body_exited"))

func _process(delta):
	if is_moving:
		move_elevator(delta)

func move_elevator(delta):
	var target_y = target_floor_index * floors_height_in_cells * grid_cell_size
	var current_y = elevator_cabin.position.y
	
	if abs(current_y - target_y) < 0.05:
		# Arrived at target floor
		elevator_cabin.position.y = target_y
		is_moving = false
		current_floor_index = target_floor_index
		update_floor_display()
		open_door()
	else:
		# Move towards target floor
		var direction = 1 if target_y > current_y else -1
		elevator_cabin.position.y += direction * movement_speed * delta

func _on_floor_button_pressed(floor_index):
	if is_moving or floor_index == current_floor_index:
		return
		
	if requires_keycard and not has_keycard:
		# Show keycard required message
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").show_prompt("Keycard required")
		await get_tree().create_timer(2.0).timeout
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()
		return
	
	target_floor_index = floor_index
	close_door()
	
	# Small delay before movement starts (simulating door closing)
	await get_tree().create_timer(1.0).timeout
	
	# Start elevator movement
	is_moving = true
	
	# Play elevator moving sound if you have one
	# if $MovingSound:
	#     $MovingSound.play()

func open_door():
	# Simple door open without animation
	if door:
		# Simulate door opening
		door.position.x = grid_cell_size  # Move door to open position
		
		# You can add a sound here if needed
		# if $DoorSound:
		#     $DoorSound.play()

func close_door():
	# Simple door close without animation
	if door:
		# Simulate door closing
		door.position.x = 0  # Move door to closed position
		
		# You can add a sound here if needed
		# if $DoorSound:
		#     $DoorSound.play()

func update_floor_display():
	if floor_display:
		floor_display.text = str(floors[current_floor_index])

func _on_interior_area_body_entered(body):
	if body.name == "Player":
		player_inside = true
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").show_prompt("Press buttons to select floor")

func _on_interior_area_body_exited(body):
	if body.name == "Player":
		player_inside = false
		if get_node_or_null("/root/Main/InteractionPrompt"):
			get_node("/root/Main/InteractionPrompt").hide_prompt()

func set_has_keycard(value):
	has_keycard = value
