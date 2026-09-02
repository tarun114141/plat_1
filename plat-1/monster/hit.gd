extends Area2D

@export var damage_type: String = "fire"
@export var damage_amount: int = 1

func _on_body_entered(body: Node2D) -> void:
	if body != get_parent() and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage_amount, damage_type)
