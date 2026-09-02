extends Node2D

var direction = 1
var speed = 200
var can_move = false

func _ready():
	await get_tree().create_timer(1.0, false).timeout
	can_move = true
	await get_tree().create_timer(8.0, false).timeout
	queue_free()

func _process(delta):
	if can_move:
		position.x += direction * speed * delta
