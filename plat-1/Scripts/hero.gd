extends CharacterBody2D

var game_over_shown := false
var game_over_scene := preload("res://Scenes/game_over.tscn")
@onready var player_hitbox: CollisionShape2D = $CollisionShape2D

signal health_changed

const SPEED = 145.0
const ACCELERATION = 1800.0
const DEACCELERATION = 3000.0
const TURN_SPEED = 3500.0
const JUMP_VELOCITY = -310.0
const JUMP_BUFFER_TIME = 0.15
const HITBOX_OFFSET = 19.5
const RAYCAST_LENGTH = 45.0

const ROLL_COOLDOWN = 0.8
const RECOIL_STRENGTH = -120.0


@export var health: int = 5
@export var max_health: int = 5
@export var attack_damage: int = 1
var can_take_damage = true
var whetstone_strikes_left: int = 0
var is_current_attack_buffed := false
var has_fire_shield: bool = false

enum State{
	IDLE,
	RUN,
	JUMP,
	ATTACK,
	ROLL,
	BLOCK,
	DAMAGE,
	DEATH
}

var state:State = State.IDLE
var attack_combo := 1
var jump_buffer := 0.0
var roll_cooldown_timer := 0.0
var facing := 1

@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_area:Area2D = $hit_area
@onready var camera:Camera2D = $Camera2D
@onready var torch_light: PointLight2D = $TorchLight
@onready var raycast: RayCast2D = get_node_or_null("RayCast2D")

# --- Audio Players (one per state) ---
@onready var sound_idle: AudioStreamPlayer2D   = $Sounds/SoundIdle
@onready var sound_run: AudioStreamPlayer2D    = $Sounds/SoundRun
@onready var sound_jump: AudioStreamPlayer2D   = $Sounds/SoundJump
@onready var sound_attack: AudioStreamPlayer2D = $Sounds/SoundAttack
@onready var sound_roll: AudioStreamPlayer2D   = $Sounds/SoundRoll
@onready var sound_block: AudioStreamPlayer2D  = $Sounds/SoundBlock
@onready var sound_damage: AudioStreamPlayer2D = $Sounds/SoundDamage
@onready var sound_death: AudioStreamPlayer2D  = $Sounds/SoundDeath

func _ready():
	# Initialize or setup RayCast2D for block striking
	if not raycast:
		if has_node("RayCast2D"):
			raycast = $RayCast2D
		else:
			raycast = RayCast2D.new()
			raycast.name = "RayCast2D"
			add_child(raycast)

	if raycast:
		raycast.position = Vector2(0, 5) # Centered on sword level
		raycast.target_position = Vector2(facing * RAYCAST_LENGTH, 0)
		raycast.enabled = true
		raycast.collision_mask = 7 # Detect environment tilemaps and enemies

	if GameManager and GameManager.has_fire_shield:
		has_fire_shield = true
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	if not hit_area.body_entered.is_connected(_on_hit_area_body_entered):
		hit_area.body_entered.connect(_on_hit_area_body_entered)
	# Disable hit area so it never fires body_entered outside of an attack
	hit_area.monitoring = false

	if torch_light:
		var current_scene = get_tree().current_scene
		var scene_path = current_scene.scene_file_path if current_scene else ""
		var is_whetstone_scene = scene_path.contains("wetstone_hunt") or (current_scene and current_scene.name.to_lower().contains("wetstone"))
		if not is_whetstone_scene:
			torch_light.enabled = false

	# Teleport hero to target spawn marker if coming from a portal
	_check_spawn_marker.call_deferred()

func _check_spawn_marker() -> void:
	await get_tree().process_frame
	if GameManager and "target_spawn_marker" in GameManager and GameManager.target_spawn_marker != "":
		var marker_name: String = GameManager.target_spawn_marker
		var current_sc = get_tree().current_scene
		if current_sc:
			var marker = current_sc.get_node_or_null(marker_name)
			if not marker:
				# Also check for child node or search recursively
				marker = _find_marker_recursive(current_sc, marker_name)
			if marker:
				global_position = marker.global_position
				print("[Hero] Teleported to spawn marker: ", marker_name, " at ", global_position)
			else:
				print("[Hero] Marker '", marker_name, "' not found in current scene.")
		GameManager.target_spawn_marker = ""

func _find_marker_recursive(node: Node, marker_name: String) -> Node:
	if node.name == marker_name:
		return node
	for child in node.get_children():
		var found = _find_marker_recursive(child, marker_name)
		if found:
			return found
	return null

func has_fire_shield_equipped() -> bool:
	if has_fire_shield:
		return true
	if GameManager and GameManager.has_fire_shield:
		return true
	return false

func increase_blade_strength(amount) -> void:
	attack_damage += amount
	print("[Hero] Blade strength increased! Current attack damage: ", attack_damage)

func activate_whetstone() -> void:
	whetstone_strikes_left = 10
	is_current_attack_buffed = false
	print("[Hero] Whetstone activated! Next 10 strikes will deal double damage.")

func toggle_torch() -> void:
	var current_scene = get_tree().current_scene
	var scene_path = current_scene.scene_file_path if current_scene else ""
	var is_whetstone_scene = scene_path.contains("wetstone_hunt") or (current_scene and current_scene.name.to_lower().contains("wetstone"))
	if not is_whetstone_scene:
		if torch_light:
			torch_light.enabled = false
		print("[Hero] The torch can only be used in the Whetstone Hunt scene!")
		return

	if torch_light:
		torch_light.enabled = not torch_light.enabled
		print("[Hero] Torch is now ", "ON" if torch_light.enabled else "OFF")

## Updates the RayCast2D orientation based on player facing direction and Up/Down inputs
## Facing Right (3 o'clock): Up -> 1 o'clock (-60°), Down -> 5 o'clock (+60°), None -> 3 o'clock (0°)
## Facing Left (9 o'clock): Up -> 11 o'clock (-120°), Down -> 7 o'clock (+120°), None -> 9 o'clock (180°)
func _update_raycast_direction() -> void:
	if not raycast:
		return
	
	var angle_deg = 0.0
	if Input.is_action_pressed("up"):
		angle_deg = -60.0 # 1 o'clock (Right) / 11 o'clock (Left)
	elif Input.is_action_pressed("down"):
		angle_deg = 60.0 # 5 o'clock (Right) / 7 o'clock (Left)

	var dir_x = facing * cos(deg_to_rad(angle_deg))
	var dir_y = sin(deg_to_rad(angle_deg))

	raycast.target_position = Vector2(dir_x, dir_y) * RAYCAST_LENGTH

## Strikes blocks and entities collided with by the RayCast2D ray
func _check_raycast_block_strike() -> void:
	if not raycast:
		return
	
	_update_raycast_direction()
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()

		if collider is TileMapLayer or collider is TileMap:
			var ray_dir = raycast.target_position.normalized()
			if ray_dir == Vector2.ZERO:
				ray_dir = Vector2(facing, 0)
			
			# Nudge slightly into the cell along ray direction to find target tile
			var target_spot = hit_point + ray_dir * 4.0 - hit_normal * 2.0
			var local_pos = collider.to_local(target_spot)
			var map_pos = collider.local_to_map(local_pos)

			var tile_data: TileData
			if collider is TileMapLayer:
				tile_data = collider.get_cell_tile_data(map_pos)
			else:
				tile_data = collider.get_cell_tile_data(0, map_pos)

			if tile_data != null:
				var is_breakable = false

				# Method 1: TileMapLayer or node named breakable
				if collider.name.to_lower().contains("breakable"):
					is_breakable = true
				# Method 2: Node is in breakable group
				elif collider.is_in_group("breakable"):
					is_breakable = true
				# Method 3: Second physics layer (index 1) for breakable tiles
				elif collider.tile_set != null and collider.tile_set.get_physics_layers_count() > 1:
					if tile_data.get_collision_polygons_count(1) > 0:
						is_breakable = true
				else:
					# Default: any solid tile hit by direct strike can be broken
					is_breakable = true

				if is_breakable:
					if collider is TileMapLayer:
						collider.erase_cell(map_pos)
					else:
						collider.erase_cell(0, map_pos)

					# Slight recoil pushback for hitting a solid tile
					velocity.x = -facing * abs(RECOIL_STRENGTH)
					print("[Hero RayCast] Destroyed block at map position: ", map_pos)

		elif collider != self and collider.has_method("take_damage"):
			var dmg = attack_damage * 2 if is_current_attack_buffed else attack_damage
			collider.take_damage(dmg)
			velocity.x = -facing * abs(RECOIL_STRENGTH)

func _deal_attack_damage():
	# Perform RayCast block & entity strike first
	_check_raycast_block_strike()

	var dmg = attack_damage * 2 if is_current_attack_buffed else attack_damage
	var damaged_targets: Array = []

	# Check all bodies currently overlapping the hit area
	for body in hit_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage") and not body in damaged_targets:
			damaged_targets.append(body)
			body.take_damage(dmg)
			velocity.x = -facing * abs(RECOIL_STRENGTH)

	# Also check any areas (such as monster or enemy hitboxes)
	for area in hit_area.get_overlapping_areas():
		var target = area.get_parent()
		if target != self and target != null and target.has_method("take_damage") and not target in damaged_targets:
			damaged_targets.append(target)
			target.take_damage(dmg)
			velocity.x = -facing * abs(RECOIL_STRENGTH)

func _physics_process(delta):

	if state == State.DEATH:
		return

	# Always update RayCast orientation according to facing and Up/Down inputs
	_update_raycast_direction()

	# Gravity
	if !is_on_floor():
		velocity += get_gravity() * delta

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER_TIME

	if jump_buffer > 0:
		jump_buffer -= delta

	# Roll cooldown countdown
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta

	# Horizontal movement (disabled while attacking/blocking)
	if state != State.ATTACK and state != State.BLOCK:

		var dir = Input.get_axis("move_left","move_right")

		if dir != 0:

			facing = sign(dir)

			sprite.flip_h = facing == -1
			hit_area.position.x = HITBOX_OFFSET * facing

			var accel = ACCELERATION

			if sign(velocity.x) != sign(dir) and velocity.x != 0:
				accel = TURN_SPEED

			velocity.x = move_toward(
				velocity.x,
				dir * SPEED,
				accel * delta
			)

		else:
			velocity.x = move_toward(
				velocity.x,
				0,
				DEACCELERATION * delta
			)

			if abs(velocity.x) < 2:
				velocity.x = 0

	# Jump
	if is_on_floor() and jump_buffer > 0 and state != State.ATTACK:

		velocity.y = JUMP_VELOCITY
		jump_buffer = 0
		_play_sound(sound_jump)

	# State changes
	if state != State.ATTACK and state != State.ROLL and state != State.BLOCK:

		if !is_on_floor():

			change_state(State.JUMP)

		elif abs(velocity.x) > 5:

			change_state(State.RUN)

		else:

			change_state(State.IDLE)

	# Inputs
	if state != State.ATTACK and state != State.ROLL and state != State.BLOCK:

		if Input.is_action_just_pressed("attack"):

			change_state(State.ATTACK)

		elif Input.is_action_just_pressed("roll") and roll_cooldown_timer <= 0:

			change_state(State.ROLL)

		elif Input.is_action_pressed("block"):

			change_state(State.BLOCK)

	# Roll movement
	if state == State.ROLL:
		velocity.x = facing * 220
		player_hitbox.shape.height=15
		player_hitbox.position.y = 17

	# Block movement
	if state == State.BLOCK:
		velocity.x = 0
	if state == State.BLOCK and not Input.is_action_pressed("block"):
		change_state(State.IDLE)

	move_and_slide()


func change_state(new_state:State):

	if state == new_state:
		return

	state = new_state

	if state != State.ROLL:
		player_hitbox.shape.height = 30
		player_hitbox.position.y = 9

	# Stop looping sounds that only play in specific states
	_stop_looping_sounds(new_state)

	match state:

		State.IDLE:
			player_hitbox.shape.height=30
			player_hitbox.position.y = 9
			sprite.play("idle")
			_play_sound(sound_idle)

		State.RUN:
			sprite.play("run")
			if not sound_run.playing:
				_play_sound(sound_run)

		State.JUMP:
			sprite.play("jump")

		State.ATTACK:
			# Shift hit area vertically based on directional input
			if Input.is_action_pressed("up"):
				hit_area.position.y = -20.0
			elif Input.is_action_pressed("down"):
				hit_area.position.y = 20.0
			else:
				hit_area.position.y = 0.0

			# Enable hit area for this attack
			hit_area.monitoring = true

			if whetstone_strikes_left > 0:
				is_current_attack_buffed = true
				whetstone_strikes_left -= 1
				print("[Hero] Whetstone strike used! Remaining buffed strikes: ", whetstone_strikes_left)
			else:
				is_current_attack_buffed = false

			if attack_combo == 1:
				sprite.play("attack_1")
				attack_combo = 2
			else:
				sprite.play("attack_2")
				attack_combo = 1
			_play_sound(sound_attack)

			# Immediately check for RayCast block strike and overlapping targets when attack starts
			_deal_attack_damage()

		State.ROLL:
			roll_cooldown_timer = ROLL_COOLDOWN
			sprite.play("roll")
			_play_sound(sound_roll)

		State.BLOCK:
			sprite.play("block")
			if not sound_block.playing:
				_play_sound(sound_block)

		State.DAMAGE:
			sprite.play("damage")
			_play_sound(sound_damage)

		State.DEATH:
			sprite.play("death")
			_play_sound(sound_death)


## ─── Audio Helpers ───────────────────────────────────────────────────────────

# Plays a sound only if it has a stream assigned.
func _play_sound(player: AudioStreamPlayer2D) -> void:
	if player and player.stream:
		player.stop()
		player.play()

# Stops looping sounds that should not continue into the new state.
func _stop_looping_sounds(new_state: State) -> void:
	if new_state != State.RUN:
		sound_run.stop()
	if new_state != State.BLOCK:
		sound_block.stop()
	if new_state != State.IDLE:
		sound_idle.stop()

## ─────────────────────────────────────────────────────────────────────────────

func _on_animation_finished():

	match state:

		State.ATTACK:
			# Disable hit area when attack animation ends
			hit_area.monitoring = false

			if abs(velocity.x) > 5:
				change_state(State.RUN)
			else:
				change_state(State.IDLE)

		State.ROLL:

			if abs(velocity.x) > 5:
				change_state(State.RUN)
			else:
				change_state(State.IDLE)

		State.DAMAGE:
			change_state(State.IDLE)

		State.DEATH:
			_show_game_over()


func take_damage(amount: int = 1, damage_type: String = "physical") -> void:
	if state == State.DEATH:
		return

	# Block checks
	if state == State.BLOCK:
		if damage_type == "fire":
			if has_fire_shield_equipped():
				_on_fire_attack_blocked()
				return
			else:
				print("[Hero] Fire bypassed normal shield! Fire Resistance Shield is required.")
		else:
			_on_attack_blocked()
			return

	if !can_take_damage:
		return

	can_take_damage = false
	health -= amount

	health = clamp(health, 0, max_health)

	emit_signal("health_changed", health)

	# Camera shake on hit
	if camera and camera.has_method("shake"):
		camera.shake(5.0, 0.3)

	# Play damage animation immediately
	if health <= 0:
		die()
		return

	change_state(State.DAMAGE)

	await get_tree().create_timer(1.0, false).timeout

	can_take_damage = true

func _on_attack_blocked() -> void:
	velocity.x = -facing * 40.0
	if sprite:
		sprite.modulate = Color(1.8, 1.8, 2.0, 1.0)
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.15)
	print("[Hero] Attack blocked!")

func _on_fire_attack_blocked() -> void:
	velocity.x = -facing * 60.0
	if sprite:
		sprite.modulate = Color(2.5, 1.3, 0.3, 1.0)
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.25)
	if camera and camera.has_method("shake"):
		camera.shake(2.5, 0.15)
	print("[Hero] Fire attack blocked with Fire Resistance Shield!")

func _show_pickup_effect() -> void:
	if sprite:
		sprite.modulate = Color(2.5, 1.5, 0.4, 1.0)
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.5)


func heal(amount: int) -> void:
	if state == State.DEATH:
		return
	health = clamp(health + amount, 0, max_health)
	emit_signal("health_changed", health)

func die():

	change_state(State.DEATH)


func _show_game_over() -> void:
	if game_over_shown:
		return
	game_over_shown = true
	# Add game over overlay to the scene tree root so it persists
	var go := game_over_scene.instantiate()
	get_tree().current_scene.add_child(go)


func _on_hit_area_body_entered(body: Node2D) -> void:
	# Only deal damage when the player is actively attacking
	if state == State.ATTACK:
		# RayCast2D handles block strikes directly
		_check_raycast_block_strike()
		
		if body != self and body.has_method("take_damage"):
			var dmg = attack_damage * 2 if is_current_attack_buffed else attack_damage
			body.take_damage(dmg)
			velocity.x = -facing * abs(RECOIL_STRENGTH)

func _on_hit_area_area_entered(area: Area2D) -> void:
	if state == State.ATTACK:
		var target = area.get_parent()
		if target != self and target != null and target.has_method("take_damage"):
			var dmg = attack_damage * 2 if is_current_attack_buffed else attack_damage
			target.take_damage(dmg)
			velocity.x = -facing * abs(RECOIL_STRENGTH)
