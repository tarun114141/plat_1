extends Area2D

## Path to the next scene (room).
@export_file("*.tscn") var next_room_path: String

## The name of the Marker2D node in the next room where the player should spawn.
@export var spawn_location_marker: String = "SpawnMarker"

## If true, this portal requires paying 10 coins to the NPC first.
@export var requires_pit_access: bool = false

var _player_in_range: bool = false

@onready var prompt_label: Label = $PromptLabel

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player_in_range and Input.is_action_just_pressed("up"):
		_transition_to_next_room()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if prompt_label:
			if requires_pit_access and GameManager and not GameManager.is_pit_access_unlocked():
				prompt_label.text = "Locked! Pay 10 Coins to NPC"
			else:
				prompt_label.text = "[W / Up] Enter Portal"
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _transition_to_next_room() -> void:
	if requires_pit_access and GameManager and not GameManager.is_pit_access_unlocked():
		print("[Portal] Locked! Pay 10 coins to the Pit Keeper NPC first.")
		var db = get_tree().get_first_node_in_group("dialogue_box")
		if db and db.has_method("start"):
			db.start([{
				"speaker": "Portal",
				"text": "The Fighting Pit portal is sealed! You must pay 10 coins to the Pit Keeper to open it."
			}])
		return

	if next_room_path != "":
		# Store the intended spawn location in the GameManager if it has the property
		if GameManager and "target_spawn_marker" in GameManager:
			GameManager.target_spawn_marker = spawn_location_marker
			
		get_tree().change_scene_to_file(next_room_path)
	else:
		push_warning("Portal has no next_room_path set!")
