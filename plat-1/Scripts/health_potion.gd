extends Area2D

@export var item_id: String = "health_potion"
@export var item_name: String = "Health Potion"
@export var icon: Texture2D = preload("res://Assets/health/full_heart.png")
@export var quantity: int = 1
@export var heal_amount: int = 1
@export var item_description: String = "Restores health when consumed."

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
	
	if item_description == "Restores health when consumed.":
		item_description = "Restores " + str(heal_amount) + " heart(s) when consumed."

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
		GameManager.add_item(item_id, item_name, icon, quantity, item_description, heal_amount, icon_path_str)
	queue_free()
