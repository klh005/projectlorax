extends Control

@onready var label = $RichTextLabel
@onready var label2 = $RichTextLabel2
@onready var background = $Background
@onready var interaction_label = $InteractionLabel

var current_page = 1
var is_visible = false

func _ready():
	# Ensure UI elements exist
	if !label:
		label = get_node_or_null("RichTextLabel")
	
	if !label2:
		label2 = get_node_or_null("RichTextLabel2")
	
	if !background:
		background = get_node_or_null("Background")
	
	if !interaction_label:
		interaction_label = get_node_or_null("InteractionLabel")
	
	# Hide UI elements initially
	if background:
		background.visible = false
	
	if label:
		label.visible = false
	
	if label2:
		label2.visible = false
	
	if interaction_label:
		interaction_label.visible = false
	
	is_visible = false

func _input(event):
	if !is_visible:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		go_next()
	elif event.is_action_pressed("interact"):
		go_next()

func show_comp():
	print("show_comp() called!")
	
	if !label or !background:
		print("Error: UI components not found!")
		return
	
	current_page = 1
	
	# Show the first page content
	if label:
		label.visible = true
	
	if label2:
		label2.visible = false
	
	if background:
		background.visible = true
	
	# Hide the interaction label
	if interaction_label:
		interaction_label.visible = false
	
	is_visible = true
	
	# Update player state to pause movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(true)
	
	# Make sure the mouse is visible for interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("CompUI should be visible now!")
	
func hide_comp():
	print("Closing CompUI")
	
	if label:
		label.visible = false
	
	if label2:
		label2.visible = false
	
	if background:
		background.visible = false
	
	is_visible = false
	current_page = 1
	
	# Update player state to resume movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(false)
	
	# Reset mouse mode for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func go_next():
	if current_page == 1:
		# Switch to second page
		if label:
			label.visible = false
		
		if label2:
			label2.visible = true
		
		current_page = 2
	else:
		# Close the computer interface after second page
		hide_comp()
