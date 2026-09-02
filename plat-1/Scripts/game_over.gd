extends CanvasLayer

# This scene is spawned when the player dies.
# It pauses the tree and shows a "YOU DIED" overlay with Restart / Quit buttons.

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

func _ready() -> void:
	# Must process while the tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # Render on top of everything

	# Create a shared AudioStreamPlayer for UI sounds
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	# Mark the player as having been defeated (used by Pit Keeper NPC dialogue)
	if GameManager:
		GameManager.player_was_defeated = true

	# --- Dark overlay ---
	var overlay := ColorRect.new()
	overlay.color = Color(0.02, 0.005, 0.005, 0.65)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# --- Centre container ---
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	# --- Panel Card with Ember Particles ---
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(460, 220)
	
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.025, 0.02, 0.88)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color(1.0, 0.52, 0.18, 0.75)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.shadow_color = Color(1.0, 0.3, 0.05, 0.18)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	# Ember particle system
	var embers := CPUParticles2D.new()
	embers.amount = 25
	embers.lifetime = 2.8
	embers.preprocess = 2.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(230, 5)
	embers.position = Vector2(230, 220)
	embers.direction = Vector2(0, -1)
	embers.spread = 25.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 20.0
	embers.initial_velocity_max = 55.0
	embers.scale_amount_min = 1.5
	embers.scale_amount_max = 3.5
	
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.85, 0.3, 0.0),
		Color(1.0, 0.65, 0.15, 0.9),
		Color(0.9, 0.28, 0.06, 0.75),
		Color(0.35, 0.06, 0.02, 0.0)
	])
	embers.color_ramp = gradient
	panel.add_child(embers)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	# --- VBox ---
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)

	# --- "YOU DIED" label ---
	var title := Label.new()
	title.text = "YOU DIED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.12, 1.0))
	vbox.add_child(title)

	# --- Button row ---
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	# Helper for Fire styled button
	var make_fire_btn = func(txt: String, cb: Callable) -> Button:
		var btn := Button.new()
		btn.text = txt
		btn.custom_minimum_size = Vector2(130, 42)
		btn.add_theme_font_size_override("font_size", 17)
		btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
		
		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.16, 0.07, 0.05, 0.88)
		normal_style.border_width_left = 1
		normal_style.border_width_top = 1
		normal_style.border_width_right = 1
		normal_style.border_width_bottom = 1
		normal_style.border_color = Color(0.7, 0.3, 0.1, 0.7)
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_right = 6
		normal_style.corner_radius_bottom_left = 6
		
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = Color(0.35, 0.13, 0.06, 0.95)
		hover_style.border_width_left = 1
		hover_style.border_width_top = 1
		hover_style.border_width_right = 1
		hover_style.border_width_bottom = 1
		hover_style.border_color = Color(1.0, 0.65, 0.15, 1.0)
		hover_style.corner_radius_top_left = 6
		hover_style.corner_radius_top_right = 6
		hover_style.corner_radius_bottom_right = 6
		hover_style.corner_radius_bottom_left = 6
		hover_style.shadow_color = Color(1.0, 0.35, 0.05, 0.25)
		hover_style.shadow_size = 4
		
		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.45, 0.1, 0.05, 1.0)
		pressed_style.border_width_left = 1
		pressed_style.border_width_top = 1
		pressed_style.border_width_right = 1
		pressed_style.border_width_bottom = 1
		pressed_style.border_color = Color(1.0, 0.85, 0.3, 1.0)
		pressed_style.corner_radius_top_left = 6
		pressed_style.corner_radius_top_right = 6
		pressed_style.corner_radius_bottom_right = 6
		pressed_style.corner_radius_bottom_left = 6
		
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("focus", hover_style)
		btn.pressed.connect(cb)
		
		# UI sounds
		btn.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
		btn.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
		btn.pressed.connect(func(): _play_ui_sound(_ui_click))
		return btn

	# Restart button
	var restart_btn: Button = make_fire_btn.call("Restart", _on_restart)
	btn_row.add_child(restart_btn)

	# Main Menu button
	var menu_btn: Button = make_fire_btn.call("Main Menu", _on_menu)
	btn_row.add_child(menu_btn)

	# Quit button
	var quit_btn: Button = make_fire_btn.call("Quit", _on_quit)
	btn_row.add_child(quit_btn)

	# Pause the game
	get_tree().paused = true

	# Auto-grab focus on restart button for gamepad / keyboard navigation
	await get_tree().process_frame
	restart_btn.grab_focus()



func _on_restart() -> void:
	get_tree().paused = false
	if GameManager:
		GameManager.respawn_player()
	else:
		get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


func _on_quit() -> void:
	get_tree().quit()

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
