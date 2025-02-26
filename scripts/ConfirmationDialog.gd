# ConfirmationDialog.gd
extends Control

var confirm_callback = null

@onready var yes_button = $Panel/VBoxContainer/HBoxContainer/YesButton
@onready var no_button = $Panel/VBoxContainer/HBoxContainer/NoButton
@onready var message_label = $Panel/VBoxContainer/MessageLabel

func _ready():
	# Create UI elements if they don't exist
	if not has_node("Panel"):
		# Create main panel
		var panel = Panel.new()
		panel.name = "Panel"
		panel.anchor_left = 0.3
		panel.anchor_top = 0.4
		panel.anchor_right = 0.7
		panel.anchor_bottom = 0.6
		add_child(panel)
		
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
		
		# Update onready vars
		yes_button = yes
		no_button = no
		message_label = label
	
	# Connect button signals
	if not yes_button.is_connected("pressed", Callable(self, "_on_yes_pressed")):
		yes_button.connect("pressed", Callable(self, "_on_yes_pressed"))
		
	if not no_button.is_connected("pressed", Callable(self, "_on_no_pressed")):
		no_button.connect("pressed", Callable(self, "_on_no_pressed"))
	
	hide()

func show_dialog(message, callback):
	message_label.text = message
	confirm_callback = callback
	
	# Fade in effect
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	show()
	
	# Pause game time but keep UI interactive
	get_tree().paused = true
	
	# Show mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_yes_pressed():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if confirm_callback:
		confirm_callback.call()
	
	confirm_callback = null

func _on_no_pressed():
	hide()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	confirm_callback = null
