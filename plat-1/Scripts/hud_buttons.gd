extends Control

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

@onready var inventory_button: Button = $MarginContainer/HBoxContainer/InventoryButton
@onready var settings_button: Button = $MarginContainer/HBoxContainer/SettingsButton

func _ready() -> void:
	# Always process even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	for btn in [inventory_button, settings_button]:
		if btn:
			btn.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.pressed.connect(func(): _play_ui_sound(_ui_click))

	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)

func _on_inventory_pressed() -> void:
	var inv = _get_target_node("InventoryUI")
	if inv and inv.has_method("toggle_inventory"):
		inv.toggle_inventory()

func _on_settings_pressed() -> void:
	var pause = _get_target_node("PauseMenu")
	if pause and pause.has_method("toggle_pause"):
		pause.toggle_pause()

func _get_target_node(node_name: String) -> Node:
	# 1. Check parent (CanvasLayer) siblings
	var parent_node = get_parent()
	if parent_node:
		if parent_node.has_node(node_name):
			return parent_node.get_node(node_name)
		for sibling in parent_node.get_children():
			if sibling.name == node_name:
				return sibling
	
	# 2. Check scene tree
	var tree_root = get_tree().current_scene
	if tree_root:
		return _find_recursive(tree_root, node_name)
	return null

func _find_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = _find_recursive(child, target_name)
		if found:
			return found
	return null

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
