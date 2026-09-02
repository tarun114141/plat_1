extends Node2D

func _ready() -> void:
	# Small delay to ensure player node is ready in the scene
	await get_tree().process_frame
	if GameManager and "target_spawn_marker" in GameManager and GameManager.target_spawn_marker != "":
		var marker = get_node_or_null(GameManager.target_spawn_marker)
		var player = get_tree().get_first_node_in_group("player")
		if marker and player:
			player.global_position = marker.global_position
		GameManager.target_spawn_marker = ""
