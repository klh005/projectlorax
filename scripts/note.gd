extends Area3D

# Signals
signal note_opened(text)
signal note_closed

# Properties
var is_open = false
var player_nearby = false

func _ready():
	# Add note to the "notes" group for easier access
	if not is_in_group("notes"):
		add_to_group("notes")
	
	# Connect signals if not already connected
	if !is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(Callable(self, "_on_body_entered"))
		
	if !is_connected("body_exited", Callable(self, "_on_body_exited")):
		body_exited.connect(Callable(self, "_on_body_exited"))

func _on_body_entered(body):
	if body.name == "Player" or body.name == "%Player":
		player_nearby = true

func _on_body_exited(body):
	if body.name == "Player" or body.name == "%Player":
		player_nearby = false
		
		# Hide any interaction prompts
		var interaction_label = get_node_or_null("/root/Main/UI/NoteUI/InteractionLabel")
		if interaction_label:
			interaction_label.visible = false

func on_looked_at():
	# Called when player's raycast hits this note
	var interaction_label = get_node_or_null("/root/Main/UI/NoteUI/InteractionLabel")
	if interaction_label:
		interaction_label.text = "Press [E] to read note"
		interaction_label.visible = true

func open_note(text):
	if is_open:
		return
		
	print("Opening note with text: ", text.substr(0, 20) + "...")
	
	# If no text provided, try to get it from child node
	if text.is_empty() and has_node("RichTextLabel"):
		text = get_node("RichTextLabel").text
	
	is_open = true
	emit_signal("note_opened", text)
	
	# Hide interaction label when note is open
	var interaction_label = get_node_or_null("/root/Main/UI/NoteUI/InteractionLabel")
	if interaction_label:
		interaction_label.visible = false

func close_note():
	if !is_open:
		return
		
	print("Closing note")
	is_open = false
	emit_signal("note_closed")
	
	# Show interaction label again if player is still nearby
	if player_nearby:
		on_looked_at()
