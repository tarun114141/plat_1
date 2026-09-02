extends CharacterBody2D

@export var speed := 250.0
@export var lifetime := 10.0
@export var spin_speed := 1.0
@export var player_pull := 200.0
@export var max_speed := 650.0

@export var grow_speed := 2.5
@export var max_scale := 1.1

var player: CharacterBody2D

var camera: Camera2D

var growing := true


func _ready():
	player = get_tree().get_first_node_in_group("player")
	camera = get_viewport().get_camera_2d()

	# start small
	scale = Vector2(0.1, 0.1)

	var angle = deg_to_rad(randf_range(45,135))
	velocity = Vector2(cos(angle), sin(angle)) * speed

	await get_tree().create_timer(lifetime, false).timeout
	queue_free()


func _physics_process(delta):

	# ---- GROW PHASE ----
	if growing:
		scale += Vector2.ONE * grow_speed * delta
		
		if scale.x >= max_scale:
			scale = Vector2.ONE * max_scale
			growing = false
		
		return


	# ---- SPIN ----
	rotation += spin_speed * delta


	# ---- WEAK PLAYER TRACKING ----
	if player:
		var dir = (player.global_position - global_position).normalized()
		velocity += dir * player_pull * delta

	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed


	# ---- COLLISION BOUNCE ----
	var collision = move_and_collide(velocity * delta)

	if collision:
		velocity = velocity.bounce(collision.get_normal())


	# ---- CAMERA EDGE BOUNCE ----
	if camera:
		var cam_pos = camera.global_position
		var screen = get_viewport_rect().size
		var half = screen / 2

		var left = cam_pos.x - half.x
		var right = cam_pos.x + half.x
		var top = cam_pos.y - half.y
		var bottom = cam_pos.y + half.y

		if global_position.x < left or global_position.x > right:
			velocity.x *= -1

		if global_position.y < top or global_position.y > bottom:
			velocity.y *= -1
