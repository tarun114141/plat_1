extends Control

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

@onready var save_confirm_label: Label = $PanelContainer/MarginContainer/VBoxContainer/SaveConfirmLabel

func _ready() -> void:
	visible = false
	process_mode = PROCESS_MODE_ALWAYS # Process input even when game is paused
	
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	var buttons = [
		$PanelContainer/MarginContainer/VBoxContainer/ResumeButton,
		$PanelContainer/MarginContainer/VBoxContainer/SaveButton,
		$PanelContainer/MarginContainer/VBoxContainer/MenuButton,
		$PanelContainer/MarginContainer/VBoxContainer/QuitButton
	]

	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.pressed.connect(func(): _play_ui_sound(_ui_click))

	$PanelContainer/MarginContainer/VBoxContainer/ResumeButton.pressed.connect(_on_resume_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/SaveButton.pressed.connect(_on_save_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/MenuButton.pressed.connect(_on_menu_pressed)
	$PanelContainer/MarginContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	
	if save_confirm_label:
		save_confirm_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	# Don't show pause menu if the player is dead/game over is shown
	var player = get_tree().get_first_node_in_group("player")
	if player and player.get("game_over_shown") == true:
		return

	visible = !visible
	get_tree().paused = visible
	
	if visible:
		if save_confirm_label:
			save_confirm_label.text = ""
		# Block mouse filters when visible
		mouse_filter = MOUSE_FILTER_STOP
		# Grab focus on the first button for gamepad / keyboard navigation
		await get_tree().process_frame
		var resume_btn = $PanelContainer/MarginContainer/VBoxContainer/ResumeButton
		if resume_btn:
			resume_btn.grab_focus()
	else:
		mouse_filter = MOUSE_FILTER_IGNORE


func _on_resume_pressed() -> void:
	toggle_pause()

func _on_save_pressed() -> void:
	if GameManager:
		GameManager.save_game()
		if save_confirm_label:
			save_confirm_label.text = "Game Saved!"
			# Auto-clear verification text after 2 seconds
			await get_tree().create_timer(2.0).timeout
			if save_confirm_label.text == "Game Saved!":
				save_confirm_label.text = ""

func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
