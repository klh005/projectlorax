extends Area3D

# Properties
var player_near = false
var is_open = false

# Signals 
signal comp_opened
signal comp_closed

func _ready():
	# Connect area signals if not already connected
	if !is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(Callable(self, "_on_body_entered"))
	
	if !is_connected("body_exited", Callable(self, "_on_body_exited")):
		body_exited.connect(Callable(self, "_on_body_exited"))
	
	# Connect signals to UI
	var ui = get_node_or_null("/root/Main/UI/CompUI")
	if ui:
		if !is_connected("comp_opened", Callable(ui, "show_comp")):
			comp_opened.connect(Callable(ui, "show_comp"))
		
		if !is_connected("comp_closed", Callable(ui, "hide_comp")):
			comp_closed.connect(Callable(ui, "hide_comp"))
	else:
		print("Warning: CompUI node not found")

func _on_body_entered(body):
	if body.name == "Player" or body.name == "%Player":
		player_near = true
		look_comp()

func _on_body_exited(body):
	if body.name == "Player" or body.name == "%Player":
		player_near = false
		
		# Hide interaction label
		var interaction_label = get_node_or_null("/root/Main/UI/CompUI/InteractionLabel")
		if interaction_label:
			interaction_label.visible = false

func look_comp():
	var interaction_label = get_node_or_null("/root/Main/UI/CompUI/InteractionLabel")
	if interaction_label:
		if is_open:
			interaction_label.visible = false
		else:
			interaction_label.text = "Press [E] to interact with computer"
			interaction_label.visible = true

func open_comp():
	if is_open:
		return
		
	print("Opening computer")
	is_open = true
	emit_signal("comp_opened")
	
	# Hide interaction label
	var interaction_label = get_node_or_null("/root/Main/UI/CompUI/InteractionLabel")
	if interaction_label:
		interaction_label.visible = false

func close_comp():
	if !is_open:
		return
		
	print("Closing computer")
	is_open = false
	emit_signal("comp_closed")
	
	# Update interaction label if player is still nearby
	if player_near:
		look_comp()
