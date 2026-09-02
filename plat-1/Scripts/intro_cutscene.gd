extends Control

# Intro Cutscene — Lore Chronicle of the Kingdom of Karam

# --- UI Sounds ---
var _ui_click: AudioStream = preload("res://Assets/sounds/ui_sounds/click.ogg")
var _ui_hover: AudioStream = preload("res://Assets/sounds/ui_sounds/hover.ogg")
var _ui_sfx_player: AudioStreamPlayer

@onready var chapter_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ChapterLabel
@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var lore_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LoreLabel
@onready var prompt_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/PromptLabel
@onready var next_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/NextButton
@onready var skip_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/SkipButton
@onready var progress_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Footer/ProgressLabel
@onready var ember_particles: CPUParticles2D = $EmberParticles

const LORE_SLIDES: Array[Dictionary] = [
	{
		"chapter": "CHRONICLES OF KARAM — CHAPTER I",
		"title": "The Shadow of the Crown",
		"text": "For three centuries, the kingdom of Karam stood unbroken beneath the sacred eternal flame.\n\nYet as the Old King's breath grew frail, the royal decree was proclaimed: the golden crown and all the lands of Karam were destined for the firstborn brother."
	},
	{
		"chapter": "CHRONICLES OF KARAM — CHAPTER II",
		"title": "The Prince's Defiance",
		"text": "You, the younger prince—forged in battle and hardened by steel—refused to kneel in the shadow of birthright.\n\nSteel clashed against stone. The royal court fractured as you raised your blade in open revolt, claiming that only true strength possesses the right to rule."
	},
	{
		"chapter": "CHRONICLES OF KARAM — CHAPTER III",
		"title": "The King's Trial",
		"text": "To stay the bloodshed of a civil war, the King struck his scepter upon the throne and delivered an immutable ultimatum:\n\n\"Neither bloodline nor birthright shall claim this crown. He who journeys into the Abyss and slays the Ancient Monster terrorizing our realm... shall be crowned King of Karam.\""
	},
	{
		"chapter": "CHRONICLES OF KARAM — CHAPTER IV",
		"title": "The Path of Ashes",
		"text": "With an unyielding spirit and a simple iron sword, you step forward onto the proving grounds.\n\nYou must master your blade, seek the legendary whetstones of the sanctuary, brew vital health elixirs, and face the monster that no mortal has ever survived.\n\nYour destiny begins now."
	}
]

var current_slide: int = 0
var is_typing: bool = false
var full_text: String = ""
var visible_chars: int = 0
var type_speed: float = 0.022
var type_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_ember_particles()
	
	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.process_mode = PROCESS_MODE_ALWAYS
	_ui_sfx_player.max_polyphony = 4
	add_child(_ui_sfx_player)

	for btn in [next_button, skip_button]:
		if btn:
			btn.mouse_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.focus_entered.connect(func(): _play_ui_sound(_ui_hover))
			btn.pressed.connect(func(): _play_ui_sound(_ui_click))

	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	if skip_button:
		skip_button.pressed.connect(_finish_cutscene)

	_show_slide(0)
	if next_button:
		next_button.grab_focus()

func _setup_ember_particles() -> void:
	if not ember_particles:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size == Vector2.ZERO:
		vp_size = Vector2(1280, 720)
	ember_particles.position = vp_size * 0.5
	ember_particles.emission_rect_extents = Vector2(vp_size.x * 0.55, vp_size.y * 0.55)
	
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if ember_particles:
		var vp_size: Vector2 = get_viewport_rect().size
		ember_particles.position = vp_size * 0.5
		ember_particles.emission_rect_extents = Vector2(vp_size.x * 0.55, vp_size.y * 0.55)

func _process(delta: float) -> void:
	# Typewriter effect
	if is_typing and lore_label:
		type_timer += delta
		if type_timer >= type_speed:
			type_timer = 0.0
			visible_chars += 1
			lore_label.visible_characters = visible_chars
			if visible_chars >= full_text.length():
				_complete_typing()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		_on_next_pressed()
		if is_inside_tree():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_finish_cutscene()
		if is_inside_tree():
			get_viewport().set_input_as_handled()

func _show_slide(index: int) -> void:
	if index < 0 or index >= LORE_SLIDES.size():
		_finish_cutscene()
		return
		
	current_slide = index
	var slide = LORE_SLIDES[current_slide]
	
	if chapter_label:
		chapter_label.text = slide["chapter"]
	if title_label:
		title_label.text = slide["title"]
	
	full_text = slide["text"]
	visible_chars = 0
	is_typing = true
	type_timer = 0.0
	
	if lore_label:
		lore_label.text = full_text
		lore_label.visible_characters = 0
		
	if progress_label:
		progress_label.text = "%d / %d" % [current_slide + 1, LORE_SLIDES.size()]
		
	if next_button:
		if current_slide == LORE_SLIDES.size() - 1:
			next_button.text = "Begin Journey"
		else:
			next_button.text = "Continue"
		next_button.grab_focus()

func _complete_typing() -> void:
	is_typing = false
	if lore_label:
		lore_label.visible_characters = -1

func _on_next_pressed() -> void:
	# If text is still typing, finish typing immediately on first press
	if is_typing:
		_complete_typing()
		return
		
	# Otherwise advance to next slide
	if current_slide + 1 < LORE_SLIDES.size():
		_show_slide(current_slide + 1)
	else:
		_finish_cutscene()

func _finish_cutscene() -> void:
	# Transition directly to the Tutorial Scene
	get_tree().change_scene_to_file("res://Scenes/tutorial.tscn")

func _play_ui_sound(stream: AudioStream) -> void:
	if _ui_sfx_player and stream:
		_ui_sfx_player.stream = stream
		_ui_sfx_player.play()
