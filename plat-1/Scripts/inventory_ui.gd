extends Control

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

@onready var panel: PanelContainer = $PanelContainer
@onready var grid_container: GridContainer = $PanelContainer/MarginContainer/VBoxContainer/ScrollContainer/GridContainer
@onready var coins_label: Label = $PanelContainer/MarginContainer/VBoxContainer/Header/CoinsLabel
@onready var close_button: Button = $PanelContainer/MarginContainer/VBoxContainer/Header/CloseButton
@onready var description_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DescriptionLabel

func _ready() -> void:
	# Hide inventory by default
	visible = false
	process_mode = PROCESS_MODE_ALWAYS # Process input even when game is paused
	
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	if close_button:
		close_button.pressed.connect(toggle_inventory)
		close_button.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
		close_button.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
		close_button.pressed.connect(func(): _play_ui_sound(_ui_click))
		
	# Connect signals from GameManager singleton
	if GameManager:
		GameManager.inventory_changed.connect(refresh_inventory)
		GameManager.coins_changed.connect(refresh_stats)
		if "karam_changed" in GameManager:
			GameManager.karam_changed.connect(refresh_stats)
		if "kill_count_changed" in GameManager:
			GameManager.kill_count_changed.connect(refresh_stats)
		refresh_stats()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and visible:
		toggle_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	visible = !visible
	if visible:
		clear_description()
		refresh_inventory()
		if GameManager:
			refresh_stats()
		# Grab focus on the first item slot or close button for gamepad navigation
		await get_tree().process_frame
		_grab_initial_focus()

func _grab_initial_focus() -> void:
	if not visible:
		return
	if grid_container and grid_container.get_child_count() > 0:
		for child in grid_container.get_children():
			if child is Button:
				child.grab_focus()
				return
	if close_button:
		close_button.grab_focus()


func refresh_coins(_amount: int = 0) -> void:
	refresh_stats()

func refresh_stats(_amount: int = 0) -> void:
	if coins_label and GameManager:
		var c: int = GameManager.coins
		var k: int = GameManager.get_karam()
		var status: String = GameManager.get_karam_status()
		var kills: int = GameManager.get_kill_count()
		coins_label.text = "Coins: %d | Karma: %d (%s) | Kills: %d" % [c, k, status, kills]

func show_description(item: Dictionary) -> void:
	if description_label:
		var item_name = item.get("name", "Item")
		var desc = item.get("description", "")
		description_label.text = item_name + " — " + desc

func clear_description() -> void:
	if description_label:
		description_label.text = "Hover over an item to view details."

func refresh_inventory() -> void:
	if not grid_container or not GameManager:
		return
		
	# Clear previous slots
	for child in grid_container.get_children():
		child.queue_free()

	var items = GameManager.get_all_items()
	
	if items.is_empty():
		var empty_label = Label.new()
		empty_label.text = "Inventory is empty"
		grid_container.add_child(empty_label)
		return

	# Build compact slots for each item
	for item in items:
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(70, 70)
		
		# Fire theme styleboxes for item slots
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0.15, 0.07, 0.05, 0.9)
		normal_style.border_width_left = 1
		normal_style.border_width_top = 1
		normal_style.border_width_right = 1
		normal_style.border_width_bottom = 1
		normal_style.border_color = Color(0.6, 0.25, 0.1, 0.7)
		normal_style.corner_radius_top_left = 6
		normal_style.corner_radius_top_right = 6
		normal_style.corner_radius_bottom_right = 6
		normal_style.corner_radius_bottom_left = 6
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.35, 0.14, 0.06, 0.95)
		hover_style.border_width_left = 2
		hover_style.border_width_top = 2
		hover_style.border_width_right = 2
		hover_style.border_width_bottom = 2
		hover_style.border_color = Color(1.0, 0.65, 0.15, 1.0)
		hover_style.corner_radius_top_left = 6
		hover_style.corner_radius_top_right = 6
		hover_style.corner_radius_bottom_right = 6
		hover_style.corner_radius_bottom_left = 6
		hover_style.shadow_color = Color(1.0, 0.35, 0.05, 0.35)
		hover_style.shadow_size = 6
		
		var pressed_style = StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.5, 0.12, 0.05, 1.0)
		pressed_style.border_width_left = 2
		pressed_style.border_width_top = 2
		pressed_style.border_width_right = 2
		pressed_style.border_width_bottom = 2
		pressed_style.border_color = Color(1.0, 0.85, 0.3, 1.0)
		pressed_style.corner_radius_top_left = 6
		pressed_style.corner_radius_top_right = 6
		pressed_style.corner_radius_bottom_right = 6
		pressed_style.corner_radius_bottom_left = 6
		
		slot.add_theme_stylebox_override("normal", normal_style)
		slot.add_theme_stylebox_override("hover", hover_style)
		slot.add_theme_stylebox_override("pressed", pressed_style)
		slot.add_theme_stylebox_override("focus", hover_style)
		
		# Slot layout
		var vbox = VBoxContainer.new()
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Icon
		var texture_rect = TextureRect.new()
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_rect.custom_minimum_size = Vector2(38, 38)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if item.get("icon") != null:
			texture_rect.texture = item["icon"]
		vbox.add_child(texture_rect)
		
		# Quantity Badge only
		var qty_label = Label.new()
		qty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		qty_label.text = "x" + str(item.get("quantity", 1))
		qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5, 1.0))
		qty_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(qty_label)
		
		slot.add_child(vbox)
		
		# Connect hover and focus signals for description box (supports both mouse and gamepad)
		var current_item = item
		slot.mouse_entered.connect(func(): 
			show_description(current_item)
			_play_ui_sound(_ui_hover)
		)
		slot.mouse_exited.connect(func(): clear_description())
		slot.focus_entered.connect(func(): 
			show_description(current_item)
			_play_ui_sound(_ui_hover)
		)
		slot.focus_exited.connect(func(): clear_description())
		
		# Connect click event to consume/use item
		var item_id = item["id"]
		slot.pressed.connect(func(): 
			_play_ui_sound(_ui_click)
			GameManager.use_item(item_id)
		)
		
		grid_container.add_child(slot)

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
