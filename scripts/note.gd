extends Area3D

@export var note_text: String = "This is a 3D note."
var interaction_label = null

signal note_closed
signal note_opened(text)
var is_open = false  # Tracks if the note is currently open

func _ready():
	add_to_group("notes")
	# We'll find the label through the scene tree
	call_deferred("find_interaction_label")

func find_interaction_label():
	# Wait a frame to make sure UI is fully initialized
	await get_tree().process_frame
	
	# Look for the interaction label in the UI
	var note_ui = get_node_or_null("/root/Main/UI/NoteUI")
	if note_ui:
		interaction_label = note_ui.get_node_or_null("InteractionLabel")
		if not interaction_label:
			print("Note: Creating missing InteractionLabel")
			interaction_label = Label.new()
			interaction_label.name = "InteractionLabel"
			interaction_label.text = "Press [E] to interact"
			interaction_label.visible = false
			interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			interaction_label.anchor_top = 0.85
			interaction_label.anchor_bottom = 0.9
			interaction_label.anchor_left = 0.2
			interaction_label.anchor_right = 0.8
			note_ui.add_child(interaction_label)
	else:
		print("Note: Could not find NoteUI node")

func on_looked_at():
	if interaction_label:
		interaction_label.text = "Press [E] to read note"
		interaction_label.visible = true
	else:
		print("Note: Missing interaction_label reference")

func open_note():
	print("Opening note: ", note_text)
	note_opened.emit(note_text)  # Emit signal to show the note UI
	is_open = true

func close_note():
	print("Closing note")
	note_closed.emit()  # Signal UI to close
	is_open = false
	
	# Hide interaction label when note is closed
	if interaction_label:
		interaction_label.visible = false
