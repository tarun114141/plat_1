extends Node

signal inventory_changed
signal coins_changed(new_amount: int)
signal karam_changed(new_amount: int)
signal karma_changed(new_amount: int)
signal kill_count_changed(new_count: int)
signal pit_access_changed(unlocked: bool)
signal input_device_changed(is_gamepad: bool)

const SAVE_PATH := "user://savegame.json"

var is_gamepad: bool = false
var coins: int = 20
var inventory: Array[Dictionary] = []

# --- Karam / Karma & Kill Tracking System ---
var karam: int = 0
var kill_count: int = 0

# --- Passive Upgrades ---
var has_fire_shield: bool = false

# --- Story & Gate Flags ---
var player_was_defeated: bool = false   # set true the first time the player dies to the monster
var pit_access_unlocked: bool = false   # set true when player pays 10 coins to enter the fighting pit

# --- Checkpoint System ---
var target_spawn_marker: String = ""
var respawn_position: Vector2 = Vector2.ZERO
var respawn_scene_path: String = ""
var saved_scene_path: String = ""
var has_checkpoint: bool = false

func _ready() -> void:
	# Process input even if game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start with cursor hidden until the mouse moves
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Mouse is in use — show cursor
		if Input.mouse_mode != Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventKey or event is InputEventMouseButton:
		if is_gamepad:
			is_gamepad = false
			emit_signal("input_device_changed", false)
		# Keyboard/mouse button pressed — hide cursor
		if event is InputEventKey:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	elif event is InputEventJoypadButton or (event is InputEventJoypadMotion and abs(event.axis_value) > 0.3):
		if not is_gamepad:
			is_gamepad = true
			emit_signal("input_device_changed", true)
		# Gamepad in use — hide cursor
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func is_using_gamepad() -> bool:
	return is_gamepad


func set_checkpoint(pos: Vector2, scene_path: String) -> void:
	respawn_position = pos
	respawn_scene_path = scene_path
	has_checkpoint = true
	print("[GameManager] Checkpoint set at: ", pos, " in scene: ", scene_path)



func add_item(item_id: String, item_name: String, icon: Texture2D = null, quantity: int = 1, description: String = "", heal_amount: int = 0, icon_path: String = "", damage_increase: int = 0) -> void:
	for item in inventory:
		if item["id"] == item_id:
			item["quantity"] += quantity
			emit_signal("inventory_changed")
			return

	var new_item = {
		"id": item_id,
		"name": item_name,
		"icon": icon,
		"icon_path": icon_path,
		"quantity": quantity,
		"description": description,
		"heal_amount": heal_amount,
		"damage_increase": damage_increase
	}
	inventory.append(new_item)
	if item_id == "fire_shield" or item_id == "fire_resistance_shield":
		has_fire_shield = true
		var player = get_tree().get_first_node_in_group("player")
		if player and "has_fire_shield" in player:
			player.has_fire_shield = true
	emit_signal("inventory_changed")

func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i]["id"] == item_id:
			inventory[i]["quantity"] -= quantity
			if inventory[i]["quantity"] <= 0:
				inventory.remove_at(i)
			emit_signal("inventory_changed")
			return true
	return false

func get_item(item_id: String) -> Dictionary:
	for item in inventory:
		if item["id"] == item_id:
			return item
	return {}

func get_all_items() -> Array[Dictionary]:
	return inventory

func use_item(item_id: String) -> bool:
	var item = get_item(item_id)
	if item.is_empty() or item["quantity"] <= 0:
		return false
		
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false
		
	var dmg_boost: int = item.get("damage_increase", 0)
	if item_id == "fire_shield" or item_id == "fire_resistance_shield":
		print("[GameManager] Fire Resistance Shield is a passive upgrade! It is automatically active when blocking.")
		return false
	elif item_id.begins_with("blade_upgrade") or item_id.begins_with("whetstone"):
		if player.has_method("activate_whetstone"):
			player.activate_whetstone()
			remove_item(item_id, 1)
			print("[GameManager] Used ", item_id, "! Whetstone activated (next 10 strikes double damage).")
			return true
		else:
			print("[GameManager] Player cannot use whetstone.")
			return false
	elif item_id == "torch":
		var current_scene = get_tree().current_scene
		var scene_path = current_scene.scene_file_path if current_scene else ""
		var is_whetstone_scene = scene_path.contains("wetstone_hunt") or (current_scene and current_scene.name.to_lower().contains("wetstone"))
		if not is_whetstone_scene:
			print("[GameManager] The torch can only be used in the Whetstone Hunt scene!")
			return false

		if player.has_method("toggle_torch"):
			player.toggle_torch()
			print("[GameManager] Toggled torch!")
			return true
		return false
	elif dmg_boost > 0:
		var boost: int = dmg_boost
		if player.has_method("increase_blade_strength"):
			player.increase_blade_strength(boost)
		elif "attack_damage" in player:
			player.attack_damage += boost
		remove_item(item_id, 1)
		print("[GameManager] Used ", item_id, "! Blade strength permanently increased by ", boost)
		return true
	elif item_id.begins_with("health_potion") or item.get("heal_amount", 0) > 0:
		if player.health >= player.max_health:
			print("Player is already at full health!")
			return false
		var amount: int = item.get("heal_amount", 1)
		player.heal(amount)
		remove_item(item_id, 1)
		return true
	else:
		print("Item ", item_id, " cannot be consumed.")
		return false

func add_coins(amount: int) -> void:
	coins += amount
	emit_signal("coins_changed", coins)

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		emit_signal("coins_changed", coins)
		# Spending coins gains karma (1 karma unit per coin spent)
		add_karam(amount)
		return true
	return false

func spend_coins_for_karma(amount: int) -> bool:
	return remove_coins(amount)

# ---------- Karam & Kill System Helpers ----------

func record_enemy_kill() -> void:
	kill_count += 1
	emit_signal("kill_count_changed", kill_count)
	add_karam(-1) # Killing an enemy reduces Karma by 1 unit
	print("[GameManager] Enemy killed! Total Kills: ", kill_count, " | Karma decreased to: ", karam)

func add_karam(amount: int) -> void:
	karam += amount
	emit_signal("karam_changed", karam)
	emit_signal("karma_changed", karam)
	print("[GameManager] Karma changed by ", amount, " | Total Karma: ", karam, " (", get_karam_status(), ")")

func get_karam() -> int:
	return karam

func add_karma(amount: int) -> void:
	add_karam(amount)

func get_karma() -> int:
	return karam

func get_kill_count() -> int:
	return kill_count

func unlock_pit_access() -> void:
	pit_access_unlocked = true
	emit_signal("pit_access_changed", true)
	print("[GameManager] Pit access unlocked!")

func is_pit_access_unlocked() -> bool:
	return pit_access_unlocked

func get_karam_status() -> String:
	if karam >= 50:
		return "Pure / Virtuous"
	elif karam >= 15:
		return "Good"
	elif karam <= -50:
		return "Vile / Corrupted"
	elif karam <= -15:
		return "Dark"
	else:
		return "Neutral"

# ---------- Save / Load System ----------

func save_game() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var player_health := 5
	if player:
		player_health = player.health

	# Serialize inventory (skip Texture2D, store icon_path instead)
	var items_data: Array = []
	for item in inventory:
		items_data.append({
			"id": item["id"],
			"name": item["name"],
			"icon_path": item.get("icon_path", ""),
			"quantity": item["quantity"],
			"description": item.get("description", ""),
			"heal_amount": item.get("heal_amount", 1),
		})

	var current_scene_path := ""
	if get_tree().current_scene:
		current_scene_path = get_tree().current_scene.scene_file_path

	var save_data := {
		"coins": coins,
		"inventory": items_data,
		"player_health": player_health,
		"scene_path": current_scene_path,
		"respawn_x": respawn_position.x,
		"respawn_y": respawn_position.y,
		"respawn_scene_path": respawn_scene_path,
		"has_checkpoint": has_checkpoint,
		"karam": karam,
		"kill_count": kill_count,
		"has_fire_shield": has_fire_shield,
		"pit_access_unlocked": pit_access_unlocked,
		"whetstone_strikes_left": player.whetstone_strikes_left if player and "whetstone_strikes_left" in player else 0,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[GameManager] Game saved.")


func load_game() -> bool:
	if not has_save():
		print("[GameManager] No save file found.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false

	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		print("[GameManager] Failed to parse save file.")
		return false

	var data: Dictionary = json.data

	# Restore coins
	coins = int(data.get("coins", 0))
	emit_signal("coins_changed", coins)

	# Restore Karam & Kills
	karam = int(data.get("karam", 0))
	kill_count = int(data.get("kill_count", 0))
	pit_access_unlocked = bool(data.get("pit_access_unlocked", false))
	emit_signal("karam_changed", karam)
	emit_signal("karma_changed", karam)
	emit_signal("kill_count_changed", kill_count)
	emit_signal("pit_access_changed", pit_access_unlocked)

	# Restore inventory
	inventory.clear()
	var items_array: Array = data.get("inventory", [])
	for item_data in items_array:
		var icon: Texture2D = null
		var icon_path: String = item_data.get("icon_path", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			icon = load(icon_path)
		inventory.append({
			"id": item_data["id"],
			"name": item_data["name"],
			"icon": icon,
			"icon_path": icon_path,
			"quantity": int(item_data.get("quantity", 1)),
			"description": item_data.get("description", ""),
			"heal_amount": int(item_data.get("heal_amount", 1)),
		})
	emit_signal("inventory_changed")

	# Restore saved scene path
	saved_scene_path = String(data.get("scene_path", ""))

	# Restore checkpoint
	has_checkpoint = bool(data.get("has_checkpoint", false))
	if has_checkpoint:
		respawn_position = Vector2(
			float(data.get("respawn_x", 0.0)),
			float(data.get("respawn_y", 0.0))
		)
		respawn_scene_path = String(data.get("respawn_scene_path", ""))
		_teleport_player_to_checkpoint()

	# Restore player health after scene is ready
	var saved_health: int = int(data.get("player_health", 5))
	_restore_player_health(saved_health)

	# Restore whetstone strikes count
	var saved_strikes: int = int(data.get("whetstone_strikes_left", 0))
	_restore_whetstone_strikes(saved_strikes)

	# Restore fire shield upgrade
	has_fire_shield = bool(data.get("has_fire_shield", false))
	_restore_fire_shield(has_fire_shield)

	print("[GameManager] Game loaded.")
	return true


func respawn_player() -> void:
	if has_checkpoint and respawn_scene_path != "" and ResourceLoader.exists(respawn_scene_path):
		var current_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
		if current_path != respawn_scene_path:
			get_tree().change_scene_to_file(respawn_scene_path)
		else:
			get_tree().reload_current_scene()

		_teleport_player_to_checkpoint()
	else:
		reset_state()
		get_tree().reload_current_scene()


func _teleport_player_to_checkpoint() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = respawn_position
		player.health = player.max_health
		player.can_take_damage = true
		player.emit_signal("health_changed", player.health)
		if "game_over_shown" in player:
			player.game_over_shown = false
		if player.has_method("change_state"):
			player.change_state(player.State.IDLE)


func _restore_player_health(hp: int) -> void:
	# Deferred so the player node exists after scene load
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health = hp
		player.emit_signal("health_changed", hp)


func _restore_whetstone_strikes(strikes: int) -> void:
	# Deferred so the player node exists after scene load
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player and "whetstone_strikes_left" in player:
		player.whetstone_strikes_left = strikes

func _restore_fire_shield(shield_active: bool) -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player and "has_fire_shield" in player:
		player.has_fire_shield = shield_active

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
		has_checkpoint = false
		respawn_position = Vector2.ZERO
		respawn_scene_path = ""
		print("[GameManager] Save file deleted.")

func reset_state() -> void:
	# Wipe current state and repopulate defaults
	coins = 20
	karam = 0
	kill_count = 0
	has_fire_shield = false
	player_was_defeated = false
	pit_access_unlocked = false
	inventory.clear()
	has_checkpoint = false
	respawn_position = Vector2.ZERO
	respawn_scene_path = ""
	saved_scene_path = ""
	emit_signal("inventory_changed")
	emit_signal("coins_changed", coins)
	emit_signal("karam_changed", karam)
	emit_signal("karma_changed", karam)
	emit_signal("kill_count_changed", kill_count)
	emit_signal("pit_access_changed", pit_access_unlocked)
	
