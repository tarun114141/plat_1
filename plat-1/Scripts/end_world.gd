extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Check if player has health and take_damage method
		if body.has_method("take_damage"):
			# Deal massive damage to ensure player loses all health
			body.take_damage(9999)
