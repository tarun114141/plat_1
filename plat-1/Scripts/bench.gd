extends Area2D

@onready var prompt_label: Label = $PromptLabel
var _player_in_range: bool = false

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	if Input.is_action_just_pressed("up"):
		_rest()

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

func _rest() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_method("heal"):
			var heal_amount = 5
			if "max_health" in player:
				heal_amount = player.max_health
			player.heal(heal_amount)
	
	if GameManager:
		var scene_path = ""
		if get_tree().current_scene:
			scene_path = get_tree().current_scene.scene_file_path
		GameManager.set_checkpoint(global_position, scene_path)
		GameManager.save_game()
		print("[Bench] Rested at bench. Health restored, game saved, and checkpoint set.")
