extends Area2D
class_name TutorialPrompt

@export_group("Keyboard Content")
## The title displayed when using Keyboard (defaults to action_title if empty)
@export var keyboard_title: String = "MOVEMENT"
## Instructional text for Keyboard users
@export_multiline var keyboard_instruction: String = "Press [A] / [D] or [Left] / [Right] to move."
## Highlighted badge for Keyboard
@export var keyboard_key_hint: String = "[A] / [D]"

@export_group("Controller / Gamepad Content")
## The title displayed when using a Gamepad (defaults to keyboard_title if empty)
@export var gamepad_title: String = ""
## Instructional text for Gamepad / Controller users
@export_multiline var gamepad_instruction: String = "Tilt [Left Analog Stick] or [D-Pad] to move."
## Highlighted badge for Gamepad / Controller
@export var gamepad_key_hint: String = "[L-STICK] / [D-PAD]"

@export_group("Behavior")
## Optional input action name (e.g. "jump", "attack", "roll", "move_left") to detect completion
@export var action_name: String = ""
## If true, prompt only displays once and never triggers again
@export var trigger_once: bool = false
## If true, prompt fades out when the player walks out of the trigger area
@export var hide_on_exit: bool = true
## Duration for fade in/out animations
@export var fade_duration: float = 0.25

# Internal state
var _player_inside: bool = false
var _has_triggered: bool = false
var _is_gamepad_mode: bool = false
var _tween: Tween

@onready var prompt_container: Control = $PromptContainer
@onready var title_label: Label = $PromptContainer/Panel/Margin/VBox/Header/TitleLabel
@onready var key_badge_label: Label = $PromptContainer/Panel/Margin/VBox/Header/KeyBadge
@onready var instruction_label: Label = $PromptContainer/Panel/Margin/VBox/InstructionLabel

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Connect to global GameManager input device updates if available
	if GameManager:
		GameManager.input_device_changed.connect(_on_device_changed)
		_is_gamepad_mode = GameManager.is_using_gamepad()
	
	_update_ui_text()
	
	if prompt_container:
		prompt_container.modulate.a = 0.0
		prompt_container.visible = false

func _input(event: InputEvent) -> void:
	# Local auto-detection as fallback
	if event is InputEventKey or event is InputEventMouseButton:
		if _is_gamepad_mode:
			_set_gamepad_mode(false)
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.3):
		if not _is_gamepad_mode:
			_set_gamepad_mode(true)

func _process(_delta: float) -> void:
	if not _player_inside or action_name == "":
		return
		
	if Input.is_action_just_pressed(action_name):
		_on_action_performed()

func _set_gamepad_mode(is_gamepad: bool) -> void:
	_is_gamepad_mode = is_gamepad
	_update_ui_text()

func _on_device_changed(is_gamepad: bool) -> void:
	_set_gamepad_mode(is_gamepad)

func _update_ui_text() -> void:
	var active_title = ""
	var active_instruction = ""
	var active_key_hint = ""
	
	if _is_gamepad_mode:
		active_title = gamepad_title if gamepad_title.strip_edges() != "" else keyboard_title
		active_instruction = gamepad_instruction if gamepad_instruction.strip_edges() != "" else keyboard_instruction
		active_key_hint = gamepad_key_hint if gamepad_key_hint.strip_edges() != "" else keyboard_key_hint
	else:
		active_title = keyboard_title
		active_instruction = keyboard_instruction
		active_key_hint = keyboard_key_hint
	
	if title_label:
		title_label.text = active_title
	if key_badge_label:
		key_badge_label.text = active_key_hint
		key_badge_label.visible = active_key_hint.strip_edges() != ""
	if instruction_label:
		instruction_label.text = active_instruction

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if trigger_once and _has_triggered:
		return
		
	_player_inside = true
	_has_triggered = true
	_show_prompt()

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	_player_inside = false
	if hide_on_exit:
		_hide_prompt()

func _show_prompt() -> void:
	if not prompt_container:
		return
		
	_update_ui_text()
	prompt_container.visible = true
	
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(prompt_container, "modulate:a", 1.0, fade_duration)
	_tween.tween_property(prompt_container, "position:y", -70.0, fade_duration).from(-55.0)

func _hide_prompt() -> void:
	if not prompt_container:
		return
		
	if _tween and _tween.is_valid():
		_tween.kill()
		
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(prompt_container, "modulate:a", 0.0, fade_duration)
	_tween.tween_property(prompt_container, "position:y", -55.0, fade_duration)
	_tween.chain().tween_callback(func():
		if not _player_inside:
			prompt_container.visible = false
	)

func _on_action_performed() -> void:
	if prompt_container and prompt_container.visible:
		var pulse_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pulse_tween.tween_property(prompt_container, "scale", Vector2(1.08, 1.08), 0.08)
		pulse_tween.tween_property(prompt_container, "scale", Vector2(1.0, 1.0), 0.12)
