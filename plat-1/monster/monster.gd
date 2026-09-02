extends CharacterBody2D
@onready var Light_d: DirectionalLight2D = $DirectionalLight2D

# --- Audio Players (one per state) ---
@onready var sound_idle: AudioStreamPlayer2D    = $Sounds/SoundIdle
@onready var sound_spawn: AudioStreamPlayer2D   = $Sounds/SoundSpawn
@onready var sound_attack: AudioStreamPlayer2D  = $Sounds/SoundAttack
@onready var sound_hurt: AudioStreamPlayer2D    = $Sounds/SoundHurt
@onready var sound_death: AudioStreamPlayer2D   = $Sounds/SoundDeath

const SwordScene = preload("res://monster/sword.tscn")
const BlockScene = preload("res://monster/blocks.tscn")
const FireballScene = preload("res://monster/fireball.tscn")
const GiantBallScene = preload("res://monster/giant_bouncy_ball.tscn")
const SpikeScene = preload("res://monster/spikes.tscn")

@export var base_max_health := 50
var max_health := 50
var health := 50

@onready var _10: Marker2D = $"10"
@onready var _00: Marker2D = $"00"
@onready var _01: Marker2D = $"01"
@onready var _02: Marker2D = $"02"
@onready var _12: Marker2D = $"12"
@onready var _22: Marker2D = $"22"
@onready var _21: Marker2D = $"21"
@onready var _20: Marker2D = $"20"

@onready var sprite: AnimatedSprite2D = ($AnimatedSprite2D if has_node("AnimatedSprite2D") else null)
var is_dead := false
var player_in_pit := false    # Monster stays idle until the player enters the pit area
var combat_started := false   # Ensures attack_loop only starts once

var markers := []
var directions := []
var current_attack = ""
@onready var anim_tree = $AnimationTree
@onready var playback = (anim_tree.get("parameters/playback") if anim_tree else null)
var attacks = ["throw", "rain", "block", "fireball", "giant_ball", "spike"]
var last_attack = ""

@onready var marker_2d: Marker2D = (get_parent().get_node_or_null("Marker2D") if get_parent() else null)

func play_anim(anim_name: String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif sprite.sprite_frames.has_animation(anim_name.capitalize()):
		sprite.play(anim_name.capitalize())
	elif sprite.sprite_frames.has_animation(anim_name.to_lower()):
		sprite.play(anim_name.to_lower())

func update_health_from_karma(_new_karma: int = 0) -> void:
	var current_karma: int = GameManager.get_karam() if GameManager else 0
	# Higher karma -> lower health; Lower karma -> higher health
	var scaled_max: int = int(max(10, base_max_health - current_karma))
	var ratio: float = float(health) / float(max_health) if max_health > 0 else 1.0
	max_health = scaled_max
	health = int(clamp(int(round(float(scaled_max) * ratio)), 1, max_health))
	print("[Monster] Karma: ", current_karma, " -> Monster Max Health: ", max_health, " (Current HP: ", health, ")")

func _ready():
	add_to_group("monster")
	if GameManager:
		if not GameManager.karam_changed.is_connected(update_health_from_karma):
			GameManager.karam_changed.connect(update_health_from_karma)
	update_health_from_karma()

	if Light_d:
		Light_d.enabled = false
	
	# Play Spawn animation on start
	play_anim("Spawn")
	_play_sound(sound_spawn)
	await get_tree().create_timer(1.0, false).timeout

	# Transition to idle — wait for player to enter the pit
	play_anim("idle")
	_play_sound(sound_idle)


func activate_combat() -> void:
	player_in_pit = true
	if not combat_started and not is_dead:
		combat_started = true
		_flash_light()   # Flash when monster wakes up to attack
		_stop_looping_sounds()
		attack_loop()

func deactivate_combat() -> void:
	player_in_pit = false

func _flash_light() -> void:
	if not Light_d:
		return
	Light_d.enabled = true
	await get_tree().create_timer(0.8, false).timeout
	if is_inside_tree():
		Light_d.enabled = false

func attack_loop():
	while not is_dead and is_inside_tree():
		# Small pause in idle between attacks
		await get_tree().create_timer(1.0, false).timeout
		if is_dead or not is_inside_tree():
			break
		# If player left the pit, idle until they return
		if not player_in_pit:
			play_anim("idle")
			_play_sound(sound_idle)
			while not player_in_pit and not is_dead and is_inside_tree():
				await get_tree().create_timer(0.2, false).timeout
			if is_dead or not is_inside_tree():
				break
		await play_random_attack()


func play_random_attack():
	if is_dead:
		return

	var attack = attacks.pick_random()
	while attack == last_attack:
		attack = attacks.pick_random()

	last_attack = attack
	current_attack = attack

	if playback:
		playback.travel(attack)

	# Play Spit animation whenever an attack plays out
	play_anim("Spit")
	_play_sound(sound_attack)

	# We MUST 'await' these calls so the loop knows when the projectiles are done
	match attack:
		"throw":
			await play_throw_attack()
		"rain":
			await play_rain()
		"block":
			await block_swap()
		"fireball":
			await fireball_play()
		"giant_ball":
			await giant_ball_attack()
		"spike":
			await spike_attack()

	# Return to idle animation when attack finishes
	if not is_dead:
		play_anim("idle")
		_play_sound(sound_idle)

# --- ATTACK FUNCTIONS (Awaiting Logic) ---

func play_throw_attack():
	var sword_speed := 400.0
	var sword_max_distance := 220.0
	var sword_reset_distance := 20.0

	markers = [_00, _01, _02, _10, _12, _20, _21, _22]
	directions.clear()
	for marker in markers:
		for child in marker.get_children():
			child.queue_free()
		directions.append(marker.position.normalized())
		spawn_sword(marker)
	for i in range(markers.size()):
		markers[i].position = directions[i] * sword_reset_distance

	var finished := false
	while not finished:
		await get_tree().process_frame
		if not is_inside_tree(): break
		if get_tree().paused: continue
		finished = true
		for i in range(markers.size()):
			var marker = markers[i]
			var dir = directions[i]
			if marker.position.length() < sword_max_distance:
				marker.position += dir * sword_speed * get_process_delta_time()
				if marker.position.length() < sword_max_distance:
					finished = false
				else:
					marker.position = dir * sword_max_distance

	await get_tree().create_timer(0.4, false).timeout
	for marker in markers:
		for child in marker.get_children():
			child.queue_free()

func play_rain() -> void:
	var rain_markers := [_10, _01, _00, _02, _12]
	for wave in range(5):
		# We don't necessarily need to await the wave itself if you want them to overlap, 
		# but the timer ensures the loop stays in this function.
		_start_rain_wave(rain_markers, 200.0, 500.0, 700.0)
		await get_tree().create_timer(0.35, false).timeout
	# Add a small buffer so the last wave can fall before the next attack starts
	await get_tree().create_timer(1.0, false).timeout

func block_swap() -> void:
	for i in 4:
		var block = BlockScene.instantiate()
		var offset_x = randf_range(-140.0, 140.0)
		var offset_y = randf_range(-35.0, -20.0)
		block.global_position = global_position + Vector2(offset_x, offset_y)
		block.direction = -1 if offset_x > 0 else 1
		if get_parent():
			get_parent().add_child(block)
		else:
			get_tree().current_scene.add_child(block)
		await get_tree().create_timer(0.35, false).timeout

func fireball_play() -> void:
	for i in range(5):
		var fireball = FireballScene.instantiate()
		fireball.global_position = global_position + Vector2(randf_range(-15.0, 15.0), -65.0 + randf_range(-10.0, 10.0))
		fireball.player = get_tree().get_first_node_in_group("player")
		if get_parent():
			get_parent().add_child(fireball)
		else:
			get_tree().current_scene.add_child(fireball)
		await get_tree().create_timer(0.35, false).timeout

func giant_ball_attack() -> void:
	var ball = GiantBallScene.instantiate()
	ball.global_position = global_position + Vector2(0, -65.0)
	ball.player = get_tree().get_first_node_in_group("player")
	if get_parent():
		get_parent().add_child(ball)
	else:
		get_tree().current_scene.add_child(ball)
	# Wait for the ball to exist for a bit before ending the attack
	await get_tree().create_timer(2.0, false).timeout

func spike_attack():
	var spike = SpikeScene.instantiate()
	if marker_2d == null and get_parent():
		marker_2d = get_parent().get_node_or_null("Marker2D")
	if marker_2d:
		marker_2d.add_child(spike)
	elif get_parent():
		spike.global_position = global_position + Vector2(randf_range(-120.0, 120.0), 0)
		get_parent().add_child(spike)
	else:
		spike.global_position = global_position + Vector2(randf_range(-120.0, 120.0), 0)
		get_tree().current_scene.add_child(spike)
	# Wait for the spike animation duration
	await get_tree().create_timer(1.5, false).timeout

# --- HELPERS ---

func _start_rain_wave(markers_list, rise_height, rise_speed, fall_speed) -> void:
	for marker in markers_list:
		if marker and randf() > 0.2: # 80% chance to drop a sword from this marker
			var sword = SwordScene.instantiate()
			# Safer to add it to the scene root rather than the monster so it doesn't move with the monster
			get_tree().current_scene.add_child(sword)
			sword.global_position = marker.global_position
			
			# Fan out based on marker's local position relative to the monster
			var dir = marker.position.normalized()
			var spread_x = dir.x * randf_range(127.5, 297.5)
			
			var peak_pos = sword.global_position + Vector2(spread_x, -rise_height)
			var end_pos = peak_pos + Vector2(dir.x * randf_range(42.5, 170.0), 1500.0)
			
			var tween = create_tween()
			var rise_duration = rise_height / rise_speed
			var fall_duration = 1500.0 / fall_speed
			
			# Point the sword along its rising trajectory rotated by 180 degrees
			var rise_dir = peak_pos - sword.global_position
			sword.rotation = rise_dir.angle() + PI
			
			# Rise up slightly and spread out horizontally
			tween.tween_property(sword, "global_position", peak_pos, rise_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			
			# Point the sword downwards along its falling trajectory at the peak (rotated back)
			tween.tween_callback(func():
				var fall_dir = end_pos - peak_pos
				sword.rotation = fall_dir.angle()
			)
			
			# Fall down past the screen and continue spreading
			tween.tween_property(sword, "global_position", end_pos, fall_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
			
			# Clean up the sword once it finishes falling
			tween.tween_callback(sword.queue_free)

func spawn_sword(marker: Marker2D):
	var sword = SwordScene.instantiate()
	marker.add_child(sword)
	sword.position = Vector2.ZERO
	
	
func take_damage(amount):
	if is_dead:
		return
	_play_sound(sound_hurt)
	health -= amount
	print("Monster Health:", health)

	# Visual flash on hit
	if sprite:
		sprite.modulate = Color(1.5, 0.3, 0.3, 1.0)
		var t = create_tween()
		t.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

	if health <= 0:
		die()
		
func die():
	if is_dead:
		return
	is_dead = true
	_stop_looping_sounds()
	print("Monster Dead")
	
	# Disable hitboxes / collision so monster cannot harm or be harmed during death animation
	if has_node("Hitbox"):
		$Hitbox.set_deferred("monitoring", false)
		$Hitbox.set_deferred("monitorable", false)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
		
	# Play Death animation
	play_anim("Death")
	_play_sound(sound_death)
	
	# Wait for death animation to finish (~1.4s)
	await get_tree().create_timer(1.4, false).timeout
	queue_free()

## ─── Audio Helpers ───────────────────────────────────────────────────────────

# Plays a sound only if it has a stream assigned.
func _play_sound(player: AudioStreamPlayer2D) -> void:
	if player and player.stream:
		player.stop()
		player.play()

# Stops looping sounds (idle).
func _stop_looping_sounds() -> void:
	if sound_idle and sound_idle.playing:
		sound_idle.stop()
