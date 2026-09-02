extends Area2D

var player_in_area: Node2D = null

func _physics_process(_delta: float) -> void:
	# Continuously deal damage while the player stays inside
	if player_in_area and player_in_area.has_method("take_damage"):
		player_in_area.take_damage(1)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = body
		# Immediate first hit
		if body.has_method("take_damage"):
			body.take_damage(1)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_area:
		player_in_area = null
