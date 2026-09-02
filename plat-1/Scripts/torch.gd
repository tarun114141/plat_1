extends Area2D

@export var item_id: String = "torch"
@export var item_name: String = "Torch"
@export var icon: Texture2D = preload("res://Assets/world_tileset.png")
@export var quantity: int = 1
@export var item_description: String = "Emits light when used (only usable in Whetstone Hunt)."

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Node2D = ($AnimatedSprite2D if has_node("AnimatedSprite2D") else ($Sprite2D if has_node("Sprite2D") else null))
@onready var point_light: PointLight2D = ($PointLight2D if has_node("PointLight2D") else null)

var player_in_range: bool = false
var _base_y: float = 0.0
var _light_base_y: float = 0.0
var _time: float = 0.0

func _ready() -> void:
	if prompt_label:
		prompt_label.visible = false
	if sprite:
		_base_y = sprite.position.y
	if point_light:
		_light_base_y = point_light.position.y
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Gentle floating hover animation
	_time += delta
	var float_offset = sin(_time * 3.0) * 4.0
	if sprite:
		sprite.position.y = _base_y + float_offset
	if point_light:
		point_light.position.y = _light_base_y + float_offset

	if player_in_range and Input.is_action_just_pressed("up"):
		_pick_up()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _pick_up() -> void:
	if GameManager:
		var icon_path_str := icon.resource_path if icon else ""
		GameManager.add_item(item_id, item_name, icon, quantity, item_description, 0, icon_path_str)
	queue_free()
