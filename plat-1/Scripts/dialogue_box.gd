extends Control

# Emitted when dialogue starts/ends (for any external listeners)
signal dialogue_started
signal dialogue_ended

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_sfx_player: AudioStreamPlayer

const TYPE_SPEED: float = 0.04   # seconds between characters

var _lines: Array[Dictionary] = []
var _current_index: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _displayed_chars: int = 0

@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerLabel
@onready var dialogue_text: Label = $Panel/Margin/VBox/DialogueText
@onready var continue_hint: Label = $Panel/Margin/VBox/ContinueHint
@onready var type_timer: Timer = $TypeTimer

func _ready() -> void:
	visible = false
	process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	type_timer.wait_time = TYPE_SPEED
	type_timer.one_shot = false
	type_timer.timeout.connect(_on_type_tick)

# ─── Public API ────────────────────────────────────────────────────────────────

## Start a dialogue sequence. Lines are filtered by the player's current karam.
## Each line dict: { "speaker", "text", "karam"?, "min_karam"?, "max_karam"? }
func start(lines: Array[Dictionary]) -> void:
	var current_karam: int = GameManager.get_karam() if GameManager else 0
	var filtered: Array[Dictionary] = []

	for line in lines:
		var min_k: int = line.get("min_karam", -9999)
		var max_k: int = line.get("max_karam", 9999)
		if current_karam >= min_k and current_karam <= max_k:
			filtered.append(line)

	if filtered.is_empty():
		return

	_lines = filtered
	_current_index = 0
	visible = true
	get_tree().paused = true
	_show_line(0)
	emit_signal("dialogue_started")

## Returns true while a dialogue sequence is active.
func is_open() -> bool:
	return visible

# ─── Internals ─────────────────────────────────────────────────────────────────

func _show_line(index: int) -> void:
	var line: Dictionary = _lines[index]
	speaker_label.text = line.get("speaker", "")
	speaker_label.visible = speaker_label.text != ""
	_full_text = line.get("text", "")
	_displayed_chars = 0
	dialogue_text.text = ""
	continue_hint.visible = false
	_is_typing = true
	type_timer.start()

func _on_type_tick() -> void:
	if _displayed_chars < _full_text.length():
		_displayed_chars += 1
		dialogue_text.text = _full_text.left(_displayed_chars)
	else:
		_finish_typing()

func _finish_typing() -> void:
	type_timer.stop()
	dialogue_text.text = _full_text
	_is_typing = false
	continue_hint.visible = true

func _advance() -> void:
	_play_ui_sound(_ui_click)
	# If still typing — skip to full text first
	if _is_typing:
		_finish_typing()
		return

	# Apply karam effect of the line that was just read
	var karam_delta: int = _lines[_current_index].get("karam", 0)
	if karam_delta != 0 and GameManager:
		GameManager.add_karam(karam_delta)

	_current_index += 1
	if _current_index >= _lines.size():
		_close()
	else:
		_show_line(_current_index)

func _close() -> void:
	type_timer.stop()
	visible = false
	get_tree().paused = false
	_lines.clear()
	_current_index = 0
	emit_signal("dialogue_ended")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("up") or event.is_action_pressed("jump"):
		_advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
