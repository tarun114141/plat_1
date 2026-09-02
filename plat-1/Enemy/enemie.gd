extends CharacterBody2D

const SPEED = 75.0
const GRAVITY = 980.0

@export var max_health := 3

var health: int
var dir := 1
var is_dead := false

@onready var ray_cast_right: RayCast2D = $ray_cast_right
@onready var ray_cast_left: RayCast2D = $ray_cast_left
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	health = max_health          # use inspector value, not parse-time default
	if animated_sprite:
		animated_sprite.play("default")  # reset sprite from saved "die" state


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Change direction when hitting a wall or when raycasts collide
	if (ray_cast_right and ray_cast_right.is_colliding()) or (dir > 0 and is_on_wall()):
		dir = -1
	elif (ray_cast_left and ray_cast_left.is_colliding()) or (dir < 0 and is_on_wall()):
		dir = 1

	# Update sprite flip according to direction
	if animated_sprite:
		animated_sprite.flip_h = (dir < 0)

	# Apply horizontal movement
	velocity.x = dir * SPEED

	move_and_slide()


func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	health -= amount

	print("Enemy Health: ", health)

	if health <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	if GameManager:
		GameManager.record_enemy_kill()
		
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("die"):
		animated_sprite.play("die")
		await animated_sprite.animation_finished
		
	queue_free()
