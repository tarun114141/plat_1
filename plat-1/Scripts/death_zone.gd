extends Area2D

## Death Zone
## Place this scene at the bottom of any level (or anywhere you want an
## instant-kill boundary).  When the player enters it:
##   1. Player is killed instantly (health -> 0).
##   2. GameManager.respawn_player() teleports them back to the last bench.
## If no bench has been rested at yet, the scene simply reloads from the start.

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	print("[DeathZone] Player entered death zone - triggering respawn.")

	# Instantly kill the player so their death state fires cleanly,
	# then let GameManager handle the respawn after a short delay.
	if body.has_method("die"):
		body.die()

	# Wait two frames so the death animation starts, then respawn
	await get_tree().process_frame
	await get_tree().process_frame

	if GameManager:
		GameManager.respawn_player()
