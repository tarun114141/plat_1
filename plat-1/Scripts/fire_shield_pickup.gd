extends Area2D

@export var item_id: String = "fire_shield"
@export var item_name: String = "Fire Resistance Shield"
@export var icon: Texture2D = preload("res://Assets/fire_shield.svg")
@export var quantity: int = 1
@export var item_description: String = "Passively allows you to block and nullify all fire attacks without taking damage."

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite2D

var player_in_range: bool = false
var _base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if sprite:
		_base_y = sprite.position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Gentle floating hover animation
	_time += delta
	if sprite:
		sprite.position.y = _base_y + sin(_time * 3.0) * 4.0

	if player_in_range and Input.is_action_just_pressed("up"):
		_pick_up()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _pick_up() -> void:
	if GameManager:
		var icon_path_str := icon.resource_path if icon else ""
		GameManager.add_item(item_id, item_name, icon, quantity, item_description, 0, icon_path_str)
		GameManager.has_fire_shield = true
		print("[Pickup] Fire Resistance Shield acquired! Fire blocking is now active.")
	
	var player = get_tree().get_first_node_in_group("player")
	if player and "has_fire_shield" in player:
		player.has_fire_shield = true
		if player.has_method("_show_pickup_effect"):
			player._show_pickup_effect()

	queue_free()
