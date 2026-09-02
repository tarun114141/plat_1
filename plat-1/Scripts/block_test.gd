extends Node2D

## Block Test HUD
## Attaches to the test scene root and displays real-time info about the
## hero's health and block state so you can verify blocking prevents damage.

@onready var hero: CharacterBody2D = $CharacterBody2D

var label: Label

func _ready() -> void:
	# Create an overlay label at the top of the screen
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	label = Label.new()
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(label)

	# Connect hero health_changed signal so we catch updates
	if hero and hero.has_signal("health_changed"):
		hero.health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if not hero:
		return

	var state_name: String = "UNKNOWN"
	# hero.state is an enum; convert to readable string
	match hero.state:
		0: state_name = "IDLE"
		1: state_name = "RUN"
		2: state_name = "JUMP"
		3: state_name = "ATTACK"
		4: state_name = "ROLL"
		5: state_name = "BLOCK"
		6: state_name = "DAMAGE"
		7: state_name = "DEATH"

	var is_blocking: bool = (hero.state == 5)  # State.BLOCK == 5

	label.text = (
		"[BLOCK TEST]\n"
		+ "HP:      %d / %d\n" % [hero.health, hero.max_health]
		+ "State:   %s\n" % state_name
		+ "Blocking: %s\n" % ("YES - damage blocked!" if is_blocking else "no")
		+ "\n"
		+ "Hold [block] while the enemy touches you.\n"
		+ "Your health should NOT decrease while blocking."
	)

	# Colour the label green when blocking, red when taking damage
	if is_blocking:
		label.modulate = Color(0.2, 1.0, 0.3)
	elif hero.state == 6:  # DAMAGE
		label.modulate = Color(1.0, 0.2, 0.2)
	else:
		label.modulate = Color(1.0, 1.0, 1.0)

func _on_health_changed(new_health: int) -> void:
	print("[BlockTest] Health changed -> ", new_health)
