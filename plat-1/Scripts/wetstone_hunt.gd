@tool
extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer

func _ready() -> void:
	if tile_map:
		_build_tilemap_level()
		
	# Spawn logic for portals
	await get_tree().process_frame
	if GameManager and "target_spawn_marker" in GameManager and GameManager.target_spawn_marker != "":
		var marker = get_node_or_null(GameManager.target_spawn_marker)
		var player = get_tree().get_first_node_in_group("player")
		if marker and player:
			player.global_position = marker.global_position
		GameManager.target_spawn_marker = ""

func _build_tilemap_level() -> void:
	var src := 0

	# Platform 1: Start Village Ground (y = 12)
	_draw_platform(src, -5, 35, 12, 4)

	# Platform 2: Slime Pass (y = 12)
	_draw_platform(src, 43, 65, 12, 4)

	# Platform 3: Stepping Ledge 1 (y = 8)
	_draw_platform(src, 72, 82, 8, 4)

	# Platform 4: Stepping Ledge 2 (y = 4)
	_draw_platform(src, 88, 98, 4, 4)

	# Platform 5: High Ridge & Midpoint Haven (y = 0)
	_draw_platform(src, 104, 130, 0, 4)

	# Platform 6: Cavern Bridge (y = 0)
	_draw_platform(src, 137, 160, 0, 4)

	# Ascending Pillars to Sanctuary (y = -4, -8, -12)
	_draw_platform(src, 166, 172, -4, 4)
	_draw_platform(src, 178, 184, -8, 4)
	_draw_platform(src, 190, 196, -12, 4)

	# Platform 7: Whetstone Sanctuary Peak (y = -16)
	_draw_platform(src, 202, 235, -16, 5)

func _draw_platform(src: int, x_start: int, x_end: int, y_top: int, height: int) -> void:
	for x in range(x_start, x_end + 1):
		# Top row grass
		var atlas_coords := Vector2i(1, 0)
		if x == x_start:
			atlas_coords = Vector2i(0, 0)
		elif x == x_end:
			atlas_coords = Vector2i(2, 0)

		tile_map.set_cell(Vector2i(x, y_top), src, atlas_coords)

		# Dirt rows underneath
		for y in range(y_top + 1, y_top + height):
			var dirt_coords := Vector2i(1, 1)
			if x == x_start:
				dirt_coords = Vector2i(0, 1)
			elif x == x_end:
				dirt_coords = Vector2i(2, 1)
			tile_map.set_cell(Vector2i(x, y), src, dirt_coords)
