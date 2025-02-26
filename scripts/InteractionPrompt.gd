# InteractionPrompt.gd
extends Control

@onready var prompt_label = $PromptLabel

func _ready():
	# Create UI if not present
	if not has_node("PromptLabel"):
		var label = Label.new()
		label.name = "PromptLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.anchor_top = 0.8  # Position near bottom of screen
		label.anchor_bottom = 0.85
		label.anchor_left = 0.2
		label.anchor_right = 0.8
		add_child(label)
		prompt_label = label
	
	hide()

func show_prompt(text):
	prompt_label.text = text
	
	# Simple fade-in without animation
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	show()

func hide_prompt():
	# Simple fade-out without animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	hide()
