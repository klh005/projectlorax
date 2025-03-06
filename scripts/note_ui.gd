extends Control

@onready var label = $RichTextLabel
@onready var background = $Background
@onready var interaction_label = $InteractionLabel

var current_page = 1
var is_visible = false

func _ready():
	# Ensure UI elements exist
	if !label:
		label = get_node_or_null("RichTextLabel")
	
	if !background:
		background = get_node_or_null("Background")
	
	if !interaction_label:
		interaction_label = get_node_or_null("InteractionLabel")
	
	# Hide UI elements initially
	if background:
		background.visible = false
	
	if label:
		label.visible = false
	
	if interaction_label:
		interaction_label.visible = false
	
	is_visible = false
	
func _process(_delta):
	if is_visible and Input.is_action_just_pressed("interact"):
		hide_note()
		
		# Notify player the UI is closed
		var player = get_node_or_null("/root/Main/Player")
		if player and player.has_method("set_ui_paused"):
			player.set_ui_paused(false)
	
func show_note(text):
	print("show_note() called with text:", text)
	
	if !label or !background:
		print("Error: UI components not found!")
		return
		
	# Show the note content
	label.text = text
	label.visible = true
	background.visible = true
	
	# Hide the interaction label
	if interaction_label:
		interaction_label.visible = false
	
	is_visible = true
	
	# Update player state to pause movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(true)
	
	print("NoteUI should be visible now!")
	
func hide_note():
	print("Closing NoteUI")
	
	if label:
		label.visible = false
	
	if background:
		background.visible = false
	
	is_visible = false
	
	# Update player state to resume movement
	var player = get_node_or_null("/root/Main/Player")
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(false)
