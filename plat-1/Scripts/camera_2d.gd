extends Camera2D

# Pixel-Perfect Smooth 2D Camera synchronized with Physics Process

@export_group("Lookahead")
@export var lookahead_distance: float = 40.0
@export var vertical_lookahead: float = 20.0
@export var horizontal_speed: float = 4.0
@export var vertical_speed: float = 3.0

var target_offset: Vector2 = Vector2.ZERO
var current_offset: Vector2 = Vector2.ZERO

# --- Camera Shake ---
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

@onready var player: Node2D = get_parent()

func _ready() -> void:
	# Run in physics lockstep with character body to eliminate sub-pixel tearing/jitter
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false

func shake(intensity: float = 4.0, duration: float = 0.25) -> void:
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func _physics_process(delta: float) -> void:
	if not player:
		return

	# --- Horizontal lookahead based on player input ---
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if abs(input_dir) > 0.1:
		target_offset.x = sign(input_dir) * lookahead_distance
	else:
		target_offset.x = 0.0

	# --- Vertical lookahead (only during sustained falling) ---
	var p_vel_y: float = 0.0
	if "velocity" in player:
		p_vel_y = player.velocity.y

	if p_vel_y > 220.0:
		target_offset.y = vertical_lookahead
	elif p_vel_y < -350.0:
		target_offset.y = -vertical_lookahead * 0.5
	else:
		target_offset.y = 0.0

	# --- Frame-rate independent smooth exponential dampening ---
	var weight_x: float = 1.0 - exp(-horizontal_speed * delta)
	var weight_y: float = 1.0 - exp(-vertical_speed * delta)
	
	current_offset.x = lerp(current_offset.x, target_offset.x, weight_x)
	current_offset.y = lerp(current_offset.y, target_offset.y, weight_y)

	# --- Camera Shake decay ---
	if shake_timer > 0.0:
		shake_timer -= delta
		var progress: float = clamp(shake_timer / shake_duration, 0.0, 1.0)
		var current_intensity: float = shake_intensity * progress
		shake_offset = Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
	else:
		shake_offset = Vector2.ZERO

	# Apply clean smoothed offset + shake without distorting player pixel coordinates
	offset = current_offset + shake_offset
