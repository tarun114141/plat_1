extends Area2D

## Invisible trigger zone around the monster's pit.
## When the player enters, it activates the monster's combat.
## When the player leaves, the monster returns to idle.

## Size of the trigger zone (width x height in pixels).
@export var trigger_size: Vector2 = Vector2(700, 400)

func _ready() -> void:
	# Build the collision shape at runtime so no sub_resource is needed in the scene file
	var shape := RectangleShape2D.new()
	shape.size = trigger_size
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		var monster = _get_monster()
		if monster and monster.has_method("activate_combat"):
			monster.activate_combat()
		if Engine.has_singleton("SoundPlayer") or get_node_or_null("/root/SoundPlayer") != null:
			SoundPlayer.play_fighting_pit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		var monster = _get_monster()
		if monster and monster.has_method("deactivate_combat"):
			monster.deactivate_combat()
		if Engine.has_singleton("SoundPlayer") or get_node_or_null("/root/SoundPlayer") != null:
			SoundPlayer.exit_fighting_pit()


func _get_monster() -> Node:
	return get_tree().get_first_node_in_group("monster")
