extends Node

# Call this function from Main's _ready() function
func setup_all_ui_elements():
	print("Setting up all UI elements...")
	setup_dialogue_ui()
	setup_interaction_prompt()
	setup_confirmation_dialog()
	setup_notification_system()
	setup_note_ui()
	print("UI setup complete!")

func setup_dialogue_ui():
	var dialogue_ui = get_node_or_null("/root/Main/UI/DialogueUI")
	if not dialogue_ui:
		print("ERROR: DialogueUI not found")
		return
		
	print("Setting up DialogueUI...")
	
	if not dialogue_ui.has_node("PanelContainer"):
		# Create main panel
		var panel = PanelContainer.new()
		panel.name = "PanelContainer"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.anchor_top = 0.7  # Position at bottom 30% of screen
		panel.anchor_bottom = 1.0
		panel.anchor_left = 0.1
		panel.anchor_right = 0.9
		dialogue_ui.add_child(panel)
		
		# Create layout container
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(vbox)
		
		# Add NPC name label
		var name_label = Label.new()
		name_label.name = "NPCName"
		name_label.text = "NPC Name"
		name_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))  # Gold color
		vbox.add_child(name_label)
		
		# Add dialogue text
		var text = Label.new()
		text.name = "DialogueText"
		text.text = "Dialogue goes here"
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(text)
		
		# Add options container
		var options = VBoxContainer.new()
		options.name = "OptionsContainer"
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(options)
	
	dialogue_ui.hide()  # Start hidden
	print("DialogueUI setup complete")

func setup_interaction_prompt():
	var prompt = get_node_or_null("/root/Main/UI/InteractionPrompt")
	if not prompt:
		print("ERROR: InteractionPrompt not found")
		return
		
	print("Setting up InteractionPrompt...")
	
	if not prompt.has_node("PromptLabel"):
		var label = Label.new()
		label.name = "PromptLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_top = 0.8  # Position near bottom of screen
		label.anchor_bottom = 0.85
		label.anchor_left = 0.2
		label.anchor_right = 0.8
		label.text = "Press E to interact"
		prompt.add_child(label)
	
	prompt.hide()  # Start hidden
	print("InteractionPrompt setup complete")

func setup_confirmation_dialog():
	var dialog = get_node_or_null("/root/Main/UI/ConfirmationDialog")
	if not dialog:
		print("ERROR: ConfirmationDialog not found")
		return
		
	print("Setting up ConfirmationDialog...")
	
	if not dialog.has_node("Panel"):
		# Create main panel
		var panel = Panel.new()
		panel.name = "Panel"
		panel.anchor_left = 0.3
		panel.anchor_top = 0.4
		panel.anchor_right = 0.7
		panel.anchor_bottom = 0.6
		dialog.add_child(panel)
		
		# Create layout container
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		panel.add_child(vbox)
		
		# Add message label
		var label = Label.new()
		label.name = "MessageLabel"
		label.text = "Are you sure?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(label)
		
		# Add button container
		var hbox = HBoxContainer.new()
		hbox.name = "HBoxContainer"
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(hbox)
		
		# Add buttons
		var yes = Button.new()
		yes.name = "YesButton"
		yes.text = "Yes"
		yes.custom_minimum_size = Vector2(100, 40)
		hbox.add_child(yes)
		
		var no = Button.new()
		no.name = "NoButton"
		no.text = "No"
		no.custom_minimum_size = Vector2(100, 40)
		hbox.add_child(no)

		# Connect button signals
		yes.connect("pressed", Callable(dialog, "_on_yes_pressed"))
		no.connect("pressed", Callable(dialog, "_on_no_pressed"))
	
	dialog.hide()  # Start hidden
	print("ConfirmationDialog setup complete")

func setup_notification_system():
	var system = get_node_or_null("/root/Main/UI/NotificationSystem")
	if not system:
		print("ERROR: NotificationSystem not found")
		return
		
	print("Setting up NotificationSystem...")
	
	if not system.has_node("NotificationLabel"):
		var label = Label.new()
		label.name = "NotificationLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_top = 0.2  # Position at top quarter of screen
		label.anchor_bottom = 0.3
		label.anchor_left = 0.1
		label.anchor_right = 0.9
		label.modulate = Color(1, 0.2, 0.2)  # Red warning color
		system.add_child(label)
	
	system.hide()  # Start hidden
	print("NotificationSystem setup complete")

func setup_note_ui():
	# Fix the note interaction label issue
	var note_ui = get_node_or_null("/root/Main/UI/NoteUI")
	if not note_ui:
		print("ERROR: NoteUI not found")
		return
		
	print("Setting up NoteUI...")
	
	# Create interaction label if it doesn't exist
	if not note_ui.has_node("InteractionLabel"):
		var label = Label.new()
		label.name = "InteractionLabel"
		label.text = "Press [E] to interact"
		label.visible = false  # Hidden by default
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_top = 0.85
		label.anchor_bottom = 0.9
		label.anchor_left = 0.2
		label.anchor_right = 0.8
		note_ui.add_child(label)
	
	print("NoteUI setup complete")
