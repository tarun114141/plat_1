extends Node2D

@export var rise_height := 70.0
@export var rise_speed := 400.0
@export var fall_speed := 600.0
@export var stay_time := 0.5

var start_y


func _ready():
	start_y = global_position.y
	await rise()
	await get_tree().create_timer(stay_time, false).timeout
	await fall()
	queue_free()


func rise():
	while global_position.y > start_y - rise_height:
		global_position.y -= rise_speed * get_process_delta_time()
		await get_tree().process_frame


func fall():
	while global_position.y < start_y:
		global_position.y += fall_speed * get_process_delta_time()
		await get_tree().process_frame
