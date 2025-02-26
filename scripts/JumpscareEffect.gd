# JumpscareEffect.gd
extends Control

@onready var flash_rect = $ColorRect

func _ready():
	# Make sure it's initially invisible
	if has_node("ColorRect"):
		$ColorRect.color.a = 0
	else:
		print("WARNING: JumpscareEffect is missing ColorRect child!")

func flash_screen():
	if !has_node("ColorRect"):
		print("ERROR: Cannot flash screen - missing ColorRect!")
		return
		
	# Create a sequence: flash white -> fade out
	var tween = create_tween()
	
	# Flash to white
	tween.tween_property($ColorRect, "color", Color(1, 1, 1, 0.8), 0.1)
	
	# Then fade out
	tween.tween_property($ColorRect, "color", Color(1, 1, 1, 0), 0.3)
	
	return tween.finished
