extends Control

var current_dialogue = null
var current_npc = null
var is_dialogue_active = false

@onready var npc_name_label = $Panel/VBoxContainer/NPCName
@onready var dialogue_text = $Panel/VBoxContainer/DialogueText
@onready var options_container = $Panel/VBoxContainer/OptionsContainer

func _ready():
	# Hide UI at start
	visible = false
	
	# Create UI elements if they don't exist
	if not has_node("Panel"):
		var panel = PanelContainer.new()
		panel.name = "Panel"
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
	
	# Clear any existing options
	for child in options_container.get_children():
		child.queue_free()

func show_dialogue(dialogue_entry, npc_name="Robot"):
	print("DialogueUI: Showing dialogue for " + npc_name)
	is_dialogue_active = true
	current_dialogue = dialogue_entry
	current_npc = npc_name
	
	if npc_name_label:
		npc_name_label.text = npc_name
	
	if dialogue_text:
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
	
	# Hide interaction prompts
	hide_interaction_prompts()
	
	# Lock player camera to dialogue position
	lock_camera_to_npc()
	
	# Pause player movement but keep UI interactive
	pause_player()
	
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
		hide_dialogue()  # Fallback if no manager

func hide_dialogue():
	print("DialogueUI: Hiding dialogue")
	is_dialogue_active = false
	current_dialogue = null
	
	# Unlock camera
	unlock_camera()
	
	# Resume player movement
	resume_player()
	
	# Simple fade-out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	visible = false
	# Restore mouse capture for gameplay
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func hide_interaction_prompts():
	# Hide all interaction prompts during dialogue
	var main = get_tree().get_current_scene()
	
	# Check for interaction prompt
	var interaction_prompt = main.get_node_or_null("UI/InteractionPrompt")
	if interaction_prompt and interaction_prompt.has_method("hide_prompt"):
		interaction_prompt.hide_prompt()
	
	# Check for note interaction label
	var note_interaction = main.get_node_or_null("UI/NoteUI/InteractionLabel")
	if note_interaction:
		note_interaction.visible = false
	
	# Check for computer interaction label
	var comp_interaction = main.get_node_or_null("UI/CompUI/InteractionLabel")
	if comp_interaction:
		comp_interaction.visible = false

func lock_camera_to_npc():
	# Find the player
	var player = get_node_or_null("/root/Main/Player")
	if !player:
		player = get_node_or_null("/root/Main/%Player")
		if !player:
			print("DialogueUI: Player not found, can't lock camera")
			return
	
	# Find the NPC
	var npc = null
	for robot in get_tree().get_nodes_in_group("npcs"):
		if robot.npc_name == current_npc:
			npc = robot
			break
	
	if !npc:
		print("DialogueUI: NPC not found for camera lock")
		return
	
	# Lock the player's view to face the NPC
	var direction = npc.global_position - player.global_position
	direction.y = 0  # Keep on horizontal plane
	
	if direction.length() > 0.01:
		var look_rotation = Quaternion(Vector3.UP, atan2(-direction.x, -direction.z))
		
		# Create a tween to smoothly rotate the player
		var tween = create_tween()
		tween.tween_property(player, "rotation:y", look_rotation.get_euler().y, 0.3)
		
		# Also adjust camera pitch if needed
		var camera = player.get_node_or_null("%PlayerCam")
		if !camera:
			camera = player.get_node_or_null("PlayerCam")
		
		if camera:
			var height_diff = npc.global_position.y - camera.global_position.y
			var distance = direction.length()
			var pitch = atan2(height_diff, distance)
			
			tween.parallel().tween_property(camera, "rotation:x", pitch, 0.3)

func unlock_camera():
	# Nothing specific needed here as player regains control normally
	pass

func pause_player():
	var player = get_node_or_null("/root/Main/Player")
	if !player:
		player = get_node_or_null("/root/Main/%Player")
	
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(true)

func resume_player():
	var player = get_node_or_null("/root/Main/Player")
	if !player:
		player = get_node_or_null("/root/Main/%Player")
	
	if player and player.has_method("set_ui_paused"):
		player.set_ui_paused(false)
