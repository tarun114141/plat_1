extends Node2D



const SPEED=180
var dir=0;


@onready var ray_left: RayCast2D = $AnimatedSprite2D/Ray_left
@onready var ray_right: RayCast2D = $AnimatedSprite2D/Ray_right
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_left_10: RayCast2D = $AnimatedSprite2D/Ray_left_10
@onready var ray_right_2: RayCast2D = $AnimatedSprite2D/Ray_right_2
@onready var ray_left_11: RayCast2D = $AnimatedSprite2D/Ray_left_11
@onready var ray_right_1: RayCast2D = $AnimatedSprite2D/Ray_right_1
@onready var ray_left_11_5: RayCast2D = $AnimatedSprite2D/Ray_left_11_5
@onready var ray_right_0_5: RayCast2D = $AnimatedSprite2D/Ray_right_0_5
@onready var ray_right_top: RayCast2D = $AnimatedSprite2D/Ray_right_top
@onready var ray_left_top: RayCast2D = $AnimatedSprite2D/Ray_left_top





# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#
	#if ray_left.is_colliding():
		#dir=-1
		#
		#animated_sprite_2d.flip_h=true
	#if ray_right.is_colliding():
		#dir=1;
		#
		#animated_sprite_2d.flip_h=false
		#
		#
	#position.x += dir*SPEED*delta
	#dir=0;
	
	#new code

#mine
#func _process(_delta):
	#if ray_right.is_colliding():
		#var R_collider = ray_right.get_collider()
		#
		#
		#if R_collider.is_in_group("player"):
			#print("Hit a character right!")
			#dir=1
			#position.x += dir*SPEED*_delta
	#if ray_left.is_colliding():
		#var L_collider = ray_left.get_collider()
		#
		#if L_collider.is_in_group("player"):
			#print("Hit a character left")
			#dir=-1
			#position.x += dir*SPEED*_delta
			#
			#
	#if ray_left_10.is_colliding():
		#var L_collider=ray_left_10.get_collider()
		#if L_collider.is_in_group("player"):
			#print("Hit a character left+++10")
			#dir=-1
			#position.x += dir*SPEED*_delta
			#
	#if ray_left_11.is_colliding():
		#var L_collider=ray_left_11.get_collider()
		#if L_collider.is_in_group("player"):
			#print("Hit a character left++++++11")
			#dir=-1
			#position.x += dir*SPEED*_delta
			#
	#if ray_right_2.is_colliding():
		#var L_collider=ray_right_2.get_collider()
		#if L_collider.is_in_group("player"):
			#print("Hit a character right++++++2")
			#dir=1
			#position.x += dir*SPEED*_delta
	#if ray_right_1.is_colliding():
		#var L_collider=ray_right_1.get_collider()
		#if L_collider.is_in_group("player"):
			#print("Hit a character right++++++1")
			#dir=1
			#position.x += dir*SPEED*_delta
# refined chatgpt
func _process(delta):
	var new_dir = 0  # temporary direction for this frame

	# Check right rays
	if ray_right.is_colliding() and ray_right.get_collider().is_in_group("player"):
		print("Hit character (right)")
		new_dir = 1
	elif ray_right_1.is_colliding() and ray_right_1.get_collider().is_in_group("player"):
		print("Hit character (right + 1)")
		new_dir = 1
	elif ray_right_2.is_colliding() and ray_right_2.get_collider().is_in_group("player"):
		print("Hit character (right + 2)")
		new_dir = 1
	elif ray_right_0_5.is_colliding() and ray_right_0_5.get_collider().is_in_group("player"):
		print("Hit 0.5")
		new_dir=1
	elif ray_right_top.is_colliding() and ray_right_top.get_collider().is_in_group("player"):
		print("Hit right top")
		new_dir=1

	# Check left rays
	elif ray_left.is_colliding() and ray_left.get_collider().is_in_group("player"):
		print("Hit character (left)")
		new_dir = -1
	elif ray_left_10.is_colliding() and ray_left_10.get_collider().is_in_group("player"):
		print("Hit character (left + 10)")
		new_dir = -1
	elif ray_left_11.is_colliding() and ray_left_11.get_collider().is_in_group("player"):
		print("Hit character (left + 11)")
		new_dir = -1
	elif ray_left_11_5.is_colliding() and ray_left_11_5.get_collider().is_in_group("player"):
		print("Hit character (left + 11_5)")
		new_dir = -1
	elif ray_left_top.is_colliding() and ray_left_top.get_collider().is_in_group("player"):
		print("Hit character (left + top)")
		new_dir = -1

	# Move only once per frame
	if new_dir != 0:
		dir = new_dir
		position.x += dir * SPEED * delta

var max_health := 3
var health := 3

func take_damage(amount: int = 1) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	if GameManager:
		GameManager.record_enemy_kill()
	queue_free()
