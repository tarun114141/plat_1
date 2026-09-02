extends Control

# ──────────────────────────────────────────────
#  UI Sounds
# ──────────────────────────────────────────────
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

# ──────────────────────────────────────────────
#  Match these to your exact AudioServer bus names
# ──────────────────────────────────────────────
const BUS_MUSIC := "music"
const BUS_SFX   := "SFX"

const SETTINGS_PATH := "user://settings.cfg"

# Common window resolutions offered to the player
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

# ── Node references built in _ready ──
var _settings_overlay: ColorRect
var _new_game_btn: Button
var _continue_btn: Button
var _settings_btn: Button
var _res_option: OptionButton
var _fs_check: CheckButton


# ═══════════════════════════════════════════════
#  Lifecycle
# ═══════════════════════════════════════════════

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Create a shared AudioStreamPlayer for UI sounds
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.bus = BUS_SFX
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)
	
	_build_background()
	_build_main_panel()
	_build_settings_panel()
	_load_settings()
	_refresh_continue()
	
	# Grab initial focus on first available button for gamepad navigation
	await get_tree().process_frame
	_grab_main_focus()

func _grab_main_focus() -> void:
	if _continue_btn and not _continue_btn.disabled:
		_continue_btn.grab_focus()
	elif _new_game_btn:
		_new_game_btn.grab_focus()


var _embers: CPUParticles2D

# ═══════════════════════════════════════════════
#  Build – Background & Particle Effects
# ═══════════════════════════════════════════════

func _build_background() -> void:
	# Deep dark background
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.015, 0.015, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Ambient rising fire ember particles across the entire menu screen
	_embers = CPUParticles2D.new()
	_embers.name = "BackgroundEmbers"
	_embers.amount = 90
	_embers.lifetime = 5.0
	_embers.preprocess = 5.0 # Pre-warms the particles so the entire screen is populated immediately
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.direction = Vector2(0, -1)
	_embers.spread = 35.0
	_embers.gravity = Vector2(0, -10)
	_embers.initial_velocity_min = 25.0
	_embers.initial_velocity_max = 75.0
	_embers.angular_velocity_min = -60.0
	_embers.angular_velocity_max = 60.0
	_embers.scale_amount_min = 1.8
	_embers.scale_amount_max = 4.2
	
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.75, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.9, 0.4, 0.0),
		Color(1.0, 0.65, 0.15, 0.9),
		Color(0.9, 0.28, 0.06, 0.75),
		Color(0.35, 0.06, 0.02, 0.0)
	])
	_embers.color_ramp = gradient
	add_child(_embers)

	_update_ember_bounds()
	get_viewport().size_changed.connect(_update_ember_bounds)

func _update_ember_bounds() -> void:
	if not _embers:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1280, 720)
	# Center the emitter and extend the rectangle to fill the entire viewport + padding
	_embers.position = vp_size * 0.5
	_embers.emission_rect_extents = Vector2(vp_size.x * 0.55, vp_size.y * 0.55)



# ═══════════════════════════════════════════════
#  Build – Main Panel
# ═══════════════════════════════════════════════

func _build_main_panel() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "PLAT - 1"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 68)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
	vbox.add_child(title)

	# Subtitle / tagline
	var sub := Label.new()
	sub.text = "A Story of Karam"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.add_theme_color_override("font_color", Color(1.0, 0.65, 0.3, 0.85))
	vbox.add_child(sub)

	# Spacer
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(sp)

	# Buttons – centred via sub-VBox
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)

	_new_game_btn = _make_btn("New Game",  _on_new_game)
	btn_box.add_child(_new_game_btn)

	_continue_btn = _make_btn("Continue", _on_continue)
	btn_box.add_child(_continue_btn)

	_settings_btn = _make_btn("Settings", _on_open_settings)
	btn_box.add_child(_settings_btn)
	btn_box.add_child(_make_btn("Quit",     _on_quit))



# ═══════════════════════════════════════════════
#  Build – Settings Panel
# ═══════════════════════════════════════════════

func _build_settings_panel() -> void:
	# Dark dimming overlay
	_settings_overlay = ColorRect.new()
	_settings_overlay.color = Color(0.02, 0.005, 0.005, 0.55)
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	# Centred card
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(480, 0)
	
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
	
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	# ── Header ──
	var header := Label.new()
	header.text = "Settings"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35, 1.0))
	vbox.add_child(header)

	vbox.add_child(HSeparator.new())

	# ── Display section ──
	_section_label(vbox, "Display")

	# Resolution
	var res_row := _make_row(vbox, "Resolution")
	_res_option = OptionButton.new()
	_res_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for r in RESOLUTIONS:
		_res_option.add_item("%d × %d" % [r.x, r.y])
	_res_option.item_selected.connect(_on_resolution_selected)
	res_row.add_child(_res_option)

	# Fullscreen
	var fs_row := _make_row(vbox, "Fullscreen")
	_fs_check = CheckButton.new()
	_fs_check.toggled.connect(_on_fullscreen_toggled)
	fs_row.add_child(_fs_check)

	vbox.add_child(HSeparator.new())

	# ── Audio section ──
	_section_label(vbox, "Audio")
	_add_audio_slider(vbox, "Master", "Master")
	_add_audio_slider(vbox, "Music",  BUS_MUSIC)
	_add_audio_slider(vbox, "SFX",   BUS_SFX)

	vbox.add_child(HSeparator.new())

	# ── Back button ──
	var back := _make_btn("Back", _on_close_settings)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(back)


# ═══════════════════════════════════════════════
#  Helper Builders
# ═══════════════════════════════════════════════

func _make_btn(txt: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.custom_minimum_size = Vector2(210, 42)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_color_override("font_color", Color(1.0, 0.92, 0.85, 1.0))
	b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	
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
	
	b.add_theme_stylebox_override("normal", normal_style)
	b.add_theme_stylebox_override("hover", hover_style)
	b.add_theme_stylebox_override("pressed", pressed_style)
	b.add_theme_stylebox_override("focus", hover_style)
	
	b.pressed.connect(cb)
	
	# UI sounds
	b.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
	b.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
	b.pressed.connect(func(): _play_ui_sound(_ui_click))
	return b

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()


func _section_label(parent: Control, txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.35, 1.0))
	parent.add_child(lbl)


func _make_row(parent: Control, label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	return row


func _add_audio_slider(parent: Control, label_text: String, bus_name: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Initialise from current bus value
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		slider.value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	else:
		slider.value = 1.0

	var pct := Label.new()
	pct.custom_minimum_size = Vector2(48, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct.text = "%d%%" % int(slider.value * 100)

	slider.value_changed.connect(func(val: float) -> void:
		pct.text = "%d%%" % int(val * 100)
		_set_bus_volume(bus_name, val)
	)

	row.add_child(slider)
	row.add_child(pct)


# ═══════════════════════════════════════════════
#  Button Callbacks
# ═══════════════════════════════════════════════

func _on_new_game() -> void:
	GameManager.reset_state()
	GameManager.delete_save()
	get_tree().change_scene_to_file("res://Scenes/intro_cutscene.tscn")


func _on_continue() -> void:
	if not GameManager.has_save():
		return
	GameManager.load_game()
	
	var scene_path: String = GameManager.saved_scene_path
	if scene_path != "" and ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	elif GameManager.respawn_scene_path != "" and ResourceLoader.exists(GameManager.respawn_scene_path):
		get_tree().change_scene_to_file(GameManager.respawn_scene_path)
	else:
		get_tree().change_scene_to_file("res://Scenes/test.tscn")


func _on_open_settings() -> void:
	# Sync UI to current state before showing
	_sync_settings_ui()
	_settings_overlay.visible = true
	await get_tree().process_frame
	if _res_option:
		_res_option.grab_focus()


func _on_close_settings() -> void:
	_settings_overlay.visible = false
	_save_settings()
	await get_tree().process_frame
	if _settings_btn:
		_settings_btn.grab_focus()



func _on_quit() -> void:
	get_tree().quit()


# ═══════════════════════════════════════════════
#  Settings Callbacks
# ═══════════════════════════════════════════════

func _on_resolution_selected(index: int) -> void:
	if index < RESOLUTIONS.size():
		var res := RESOLUTIONS[index]
		# Only change if not fullscreen (fullscreen ignores window size)
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_size(res)
			var screen := DisplayServer.screen_get_size()
			var win   := DisplayServer.window_get_size()
			DisplayServer.window_set_position((screen - win) / 2)


func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Re-apply the chosen resolution after leaving fullscreen
		_on_resolution_selected(_res_option.selected)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))


# ═══════════════════════════════════════════════
#  State helpers
# ═══════════════════════════════════════════════

func _refresh_continue() -> void:
	if _continue_btn:
		_continue_btn.disabled = not GameManager.has_save()


func _sync_settings_ui() -> void:
	# Fullscreen state
	var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if _fs_check:
		_fs_check.set_pressed_no_signal(is_fs)

	# Resolution index
	if _res_option:
		var win_size := DisplayServer.window_get_size()
		for i in RESOLUTIONS.size():
			if RESOLUTIONS[i] == win_size:
				_res_option.select(i)
				break


# ═══════════════════════════════════════════════
#  Save / Load Settings  (user://settings.cfg)
# ═══════════════════════════════════════════════

func _save_settings() -> void:
	var cfg := ConfigFile.new()

	# Display
	cfg.set_value("display", "fullscreen",
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	var win := DisplayServer.window_get_size()
	var res_idx := 0
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == win:
			res_idx = i
			break
	cfg.set_value("display", "resolution_index", res_idx)

	# Audio buses
	for bus in ["Master", BUS_MUSIC, BUS_SFX]:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			cfg.set_value("audio", bus.to_lower(),
				AudioServer.get_bus_volume_db(idx))

	cfg.save(SETTINGS_PATH)
	print("[MainMenu] Settings saved.")


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return

	# Display
	var fullscreen: bool = cfg.get_value("display", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	var res_idx: int = cfg.get_value("display", "resolution_index", 0)
	_on_resolution_selected(res_idx)

	# Audio
	for bus in ["Master", BUS_MUSIC, BUS_SFX]:
		var idx := AudioServer.get_bus_index(bus)
		if idx >= 0:
			var vol: float = cfg.get_value("audio", bus.to_lower(), 0.0)
			AudioServer.set_bus_volume_db(idx, vol)

	print("[MainMenu] Settings loaded.")
