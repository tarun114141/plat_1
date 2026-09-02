extends AnimatableBody2D

@onready var detector: Area2D = $PlayerDetector

var _players_in_area: Array[Node2D] = []
var _anim_player: AnimationPlayer = null
var _leave_timer: float = 0.0
const LEAVE_DELAY: float = 0.25

func _ready() -> void:
	sync_to_physics = true
	if detector:
		detector.body_entered.connect(_on_body_entered)
		detector.body_exited.connect(_on_body_exited)
	call_deferred("_update_movement")

func _physics_process(delta: float) -> void:
	if _leave_timer > 0:
		_leave_timer -= delta
		if _leave_timer <= 0:
			_update_movement()

func _get_anim_player() -> AnimationPlayer:
	if _anim_player and is_instance_valid(_anim_player):
		return _anim_player
	_anim_player = find_child("AnimationPlayer", true, false)
	if not _anim_player and get_parent():
		_anim_player = get_parent().find_child("AnimationPlayer", true, false)
	return _anim_player

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		if not _players_in_area.has(body):
			_players_in_area.append(body)
		_leave_timer = 0.0
		_update_movement()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		_players_in_area.erase(body)
		_leave_timer = LEAVE_DELAY

func _update_movement() -> void:
	var anim = _get_anim_player()
	if not anim:
		return
		
	anim.callback_mode_process = AnimationPlayer.ANIMATION_PROCESS_PHYSICS
		
	if _players_in_area.size() > 0:
		if not anim.is_playing():
			if anim.assigned_animation != "" and anim.assigned_animation != "RESET":
				anim.play(anim.assigned_animation)
			elif anim.has_animation("new_animation"):
				anim.play("new_animation")
			else:
				var list = anim.get_animation_list()
				for a in list:
					if a != "RESET":
						anim.play(a)
						break
	else:
		if _leave_timer <= 0 and anim.is_playing():
			anim.pause()
