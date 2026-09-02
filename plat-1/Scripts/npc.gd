extends Area2D

## Name shown in the dialogue box speaker label.
@export var npc_name: String = "Villager"

## Dialogue lines for this NPC.
## Each Dictionary can have:
##   "speaker"   : String  — overrides npc_name for that line (optional)
##   "text"      : String  — the line to display
##   "karam"     : int     — karam added AFTER the player reads this line (optional, default 0)
##   "min_karam" : int     — only shown if player karam >= this value (optional)
##   "max_karam" : int     — only shown if player karam <= this value (optional)
@export var dialogue_lines: Array[Dictionary] = []

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: bool = false

func _ready() -> void:
	add_to_group("npc")
	process_mode = PROCESS_MODE_ALWAYS
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Populate default test lines if none are set in inspector
	if dialogue_lines.is_empty():
		_populate_default_lines()

func _populate_default_lines() -> void:
	dialogue_lines = [
		{
			"speaker": npc_name,
			"text": "Hello there, traveller. The road ahead is treacherous — watch your step.",
		},
		{
			"speaker": npc_name,
			"text": "Those who walk in darkness shall find only shadows. But those with virtue... they find light.",
			"karam": 1,          # +1 karam just for listening
		},
		{
			"speaker": npc_name,
			"text": "I sense great purity in your soul. May your blade stay sharp and your heart true.",
			"min_karam": 15,     # Only shown if player is Good or better
		},
		{
			"speaker": npc_name,
			"text": "I see darkness clinging to you. Tread carefully, lest it consume you.",
			"max_karam": -1,     # Only shown if player has negative karam
		},
		{
			"speaker": npc_name,
			"text": "Safe travels. Return if you ever need rest.",
		},
	]

func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	# Don't open a new dialogue if one is already running
	var db = _get_dialogue_box()
	if db and db.is_open():
		return

	if Input.is_action_just_pressed("up"):
		_start_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _start_dialogue() -> void:
	var db = _get_dialogue_box()
	if db:
		# Inject speaker name into any lines that don't override it
		var lines_with_speaker: Array[Dictionary] = []
		for line in dialogue_lines:
			var l = line.duplicate()
			if not l.has("speaker") or l["speaker"] == "":
				l["speaker"] = npc_name
			lines_with_speaker.append(l)
		db.start(lines_with_speaker)
		if prompt_label:
			prompt_label.visible = false

func _get_dialogue_box() -> Node:
	return get_tree().get_first_node_in_group("dialogue_box")
