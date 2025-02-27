# GameState.gd (AutoLoad version)
extends Node

signal game_started
signal keycard_collected
signal flashlight_collected
signal factory_shutdown_attempted

var is_game_active: bool = false
var has_keycard: bool = false
var has_flashlight: bool = false
var collected_items: Array = []
var shutdown_attempted: bool = false

# Environment control
var emergency_lights_on: bool = false
var alarm_active: bool = false

func _ready():
	pass

func reset():
	is_game_active = false
	has_keycard = false
	has_flashlight = false
	collected_items = []
	shutdown_attempted = false
	emergency_lights_on = false
	alarm_active = false

func start_game():
	if is_game_active:
		return
		
	is_game_active = true
	print("Factory defense mode activated! Robots are now hostile.")
	
	# Make all NPCs hostile
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc.has_method("become_hostile"):
			print("Robot becoming hostile: ", npc.name)
			npc.become_hostile()
	
	# Lock exit doors
	for door in get_tree().get_nodes_in_group("doors"):
		if door.door_id in ["exit_door", "control_room_door"]:
			door.locked = true
	
	# Turn off main lights, activate emergency lights
	emergency_lights_on = true
	for light in get_tree().get_nodes_in_group("main_lights"):
		if light is Light3D:
			light.visible = false
	
	for light in get_tree().get_nodes_in_group("emergency_lights"):
		if light is Light3D:
			light.visible = true
	
	# Start alarm sound if there's a global alarm node
	alarm_active = true
	var alarm = get_node_or_null("/root/Main/AlarmSound")
	if alarm and alarm is AudioStreamPlayer:
		alarm.play()
	
	emit_signal("game_started")
	emit_signal("factory_shutdown_attempted")
	
	# Show notification message
	show_notification("ALERT: Factory robots have detected your attempt to shut down operations. Escape is now your priority.", 5.0)
	
	shutdown_attempted = true

func collect_keycard():
	has_keycard = true
	emit_signal("keycard_collected")
	show_notification("Security keycard acquired. You can now access the control room.", 3.0)
	
	# Update elevator and door access
	for elevator in get_tree().get_nodes_in_group("elevators"):
		if elevator.has_method("set_has_keycard"):
			elevator.set_has_keycard(true)

func collect_flashlight():
	has_flashlight = true
	emit_signal("flashlight_collected") 
	show_notification("Flashlight acquired. You can now explore dark areas.", 3.0)

func collect_item(item_id):
	if not collected_items.has(item_id):
		collected_items.append(item_id)
		show_notification("Item collected: " + item_id, 2.0)

func show_notification(text, duration = 3.0):
	var notification_system = get_node_or_null("/root/Main/UI/NotificationSystem")
	if notification_system and notification_system.has_method("show_notification"):
		notification_system.show_notification(text, duration)
	else:
		# Fallback if notification system not found
		print("NOTIFICATION: " + text)
