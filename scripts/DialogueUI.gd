# DialogueUI.gd
extends Control

var current_dialogue = null

@onready var npc_name_label = $Panel/VBoxContainer/NPCName
@onready var dialogue_text = $Panel/VBoxContainer/DialogueText
@onready var options_container = $Panel/VBoxContainer/OptionsContainer

func _ready():
	# Hide UI at start
	hide()
	
	# Create UI elements if they don't exist
	if not has_node("PanelContainer"):
		var panel = PanelContainer.new()
		panel.name = "PanelContainer"
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.anchor_top = 0.7  # Position at bottom 30% of screen
		panel.anchor_bottom = 1.0
		panel.anchor_left = 0.1
		panel.anchor_right = 0.9
		add_child(panel)
		
		var vbox = VBoxContainer.new()
		vbox.name = "VBoxContainer"
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.add_child(vbox)
		
		var name_label = Label.new()
		name_label.name = "NPCName"
		name_label.text = "NPC Name"
		name_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))  # Gold-ish color
		vbox.add_child(name_label)
		
		var text = Label.new()
		text.name = "DialogueText"
		text.text = "Dialogue goes here"
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vbox.add_child(text)
		
		var options = VBoxContainer.new()
		options.name = "OptionsContainer"
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(options)
		
		# Update onready vars
		npc_name_label = name_label
		dialogue_text = text
		options_container = options
	
	for child in options_container.get_children():
		child.queue_free()

func show_dialogue(dialogue_entry, npc_name="Robot"):
	print("DialogueUI: Showing dialogue for " + npc_name)
	current_dialogue = dialogue_entry
	npc_name_label.text = npc_name
	dialogue_text.text = dialogue_entry["text"]
	
	# Clear previous options
	for child in options_container.get_children():
		child.queue_free()
	
	# Add options if they exist
	if dialogue_entry.has("options"):
		for i in range(dialogue_entry["options"].size()):
			var option = dialogue_entry["options"][i]
			var button = Button.new()
			button.text = option["text"]
			button.connect("pressed", Callable(self, "_on_option_selected").bind(i))
			options_container.add_child(button)
	else:
		# Add a "Continue" button if no options
		var button = Button.new()
		button.text = "Continue"
		button.connect("pressed", Callable(self, "_on_continue_pressed"))
		options_container.add_child(button)
	
	# Simple fade-in effect
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	show()
	# Show mouse for dialogue
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_option_selected(index):
	print("DialogueUI: Option selected: " + str(index))
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.advance_dialogue(index)
	else:
		print("DialogueUI: DialogueManager not found!")

func _on_continue_pressed():
	print("DialogueUI: Continue pressed")
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.advance_dialogue()
	else:
		print("DialogueUI: DialogueManager not found!")

func hide_dialogue():
	print("DialogueUI: Hiding dialogue")
	current_dialogue = null
	
	# Simple fade-out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	hide()
	# Restore mouse capture for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
