extends Area2D

@export var coin_amount: int = 1

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coin_chrime: AudioStreamPlayer2D = $coin_chrime

var _coin_sound: AudioStream = preload("res://Assets/sounds/coin.wav")

func _ready() -> void:
	if coin_chrime and not coin_chrime.stream:
		coin_chrime.stream = _coin_sound

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if GameManager:
			GameManager.add_coins(coin_amount)

		if coin_chrime:
			if not coin_chrime.stream:
				coin_chrime.stream = _coin_sound
			coin_chrime.play()
		
		if animation_player and animation_player.has_animation("pickup_animation"):
			animation_player.play("pickup_animation")
		else:
			queue_free()
