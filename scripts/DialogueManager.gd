# DialogueManager.gd
extends Node

signal dialogue_started(npc_name)
signal dialogue_ended

var is_dialogue_active = false
var current_npc = null
var dialogue_data = {}

func _ready():
	# Load dialogue data from JSON
	load_dialogue_data()

func load_dialogue_data():
	if FileAccess.file_exists("res://data/dialogue.json"):
		var file = FileAccess.open("res://data/dialogue.json", FileAccess.READ)
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			dialogue_data = json.get_data()
		else:
			print("Error parsing dialogue JSON: ", json.get_error_message())
		file.close()
	else:
		print("Dialogue file not found, using fallback dialogue")
		# Fallback dialogue if file doesn't exist
		dialogue_data = {
			"robot1": {
				"greeting": {
					"text": "Hello human! I am a friendly robot. How can I assist you today?",
					"options": [
						{"text": "What is this place?", "next": "place_info"},
						{"text": "How do I get out of here?", "next": "escape_info"},
						{"text": "Goodbye.", "next": "end"}
					]
				},
				"place_info": {
					"text": "This is a research facility. We were working on advanced AI, but something went wrong...",
					"options": [
						{"text": "What went wrong?", "next": "problem_info"},
						{"text": "Let's talk about something else.", "next": "greeting"}
					]
				},
				"problem_info": {
					"text": "The AI systems became unstable. Some robots may turn hostile if the emergency button is pressed.",
					"options": [
						{"text": "I'll be careful.", "next": "end"},
						{"text": "Let's talk about something else.", "next": "greeting"}
					]
				},
				"escape_info": {
					"text": "The exit is on the top floor. You can use the elevator to get there.",
					"options": [
						{"text": "Thanks for the info.", "next": "end"},
						{"text": "Let's talk about something else.", "next": "greeting"}
					]
				}
			}
		}

func start_dialogue(npc_id, npc_name):
	if is_dialogue_active:
		return
		
	if not dialogue_data.has(npc_id):
		print("No dialogue found for NPC: ", npc_id)
		return
		
	is_dialogue_active = true
	current_npc = npc_id
	emit_signal("dialogue_started", npc_name)
	
	if get_node_or_null("/root/Main/DialogueUI"):
		get_node("/root/Main/DialogueUI").show_dialogue(dialogue_data[npc_id]["greeting"], npc_name)
	else:
		print("DialogueUI not found!")

func advance_dialogue(option_index = 0):
	if not is_dialogue_active:
		return
		
	var npc_dialogues = dialogue_data[current_npc]
	var current_dialogue = get_node("/root/Main/DialogueUI").current_dialogue
	
	if current_dialogue.has("options") and current_dialogue["options"].size() > option_index:
		var next_id = current_dialogue["options"][option_index]["next"]
		if next_id == "end":
			end_dialogue()
		else:
			get_node("/root/Main/DialogueUI").show_dialogue(npc_dialogues[next_id], dialogue_data[current_npc]["name"] if dialogue_data[current_npc].has("name") else "Robot")
	else:
		# If no options, just end dialogue
		end_dialogue()

func end_dialogue():
	is_dialogue_active = false
	current_npc = null
	if get_node_or_null("/root/Main/DialogueUI"):
		get_node("/root/Main/DialogueUI").hide_dialogue()
	emit_signal("dialogue_ended")

func _input(event):
	# Allow pressing ESC to exit dialogue
	if is_dialogue_active and event.is_action_pressed("cancel"):
		end_dialogue()
