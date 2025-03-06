extends Control

@onready var prompt_label = $PromptLabel
var current_text = ""
var is_visible = false
var fade_tween = null

func _ready():
	# Create UI if not present
	if !prompt_label:
		prompt_label = get_node_or_null("PromptLabel")
		
		if !prompt_label:
			prompt_label = Label.new()
			prompt_label.name = "PromptLabel"
			prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			
			# Position near bottom of screen
			prompt_label.anchor_top = 0.8
			prompt_label.anchor_bottom = 0.9
			prompt_label.anchor_left = 0.2
			prompt_label.anchor_right = 0.8
			
			# Make it stand out better
			prompt_label.add_theme_color_override("font_color", Color(1, 1, 1))
			prompt_label.add_theme_font_size_override("font_size", 18)
			
			# Add to parent
			add_child(prompt_label)
	
	# Start hidden
	is_visible = false
	modulate.a = 0
	hide()

func show_prompt(text):
	current_text = text
	prompt_label.text = text
	
	# Cancel any existing fade tween
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Simple fade-in
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	is_visible = true
	show()

func hide_prompt():
	if !is_visible:
		return
	
	# Cancel any existing fade tween
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	
	# Simple fade-out
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.2)
	fade_tween.tween_callback(Callable(self, "_on_fade_complete"))
	
	is_visible = false

func _on_fade_complete():
	hide()

func update_prompt(text):
	if text == current_text:
		return
	
	# If already visible, just update the text
	if is_visible:
		prompt_label.text = text
		current_text = text
	else:
		# Otherwise show as normal
		show_prompt(text)
