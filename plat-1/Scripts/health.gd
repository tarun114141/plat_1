extends Control


@onready var player = get_tree().get_first_node_in_group("player")
@export var heart_full: Texture2D
@export var heart_empty: Texture2D

@onready var container = $HBoxContainer

var max_hearts = 5


func _ready():


	for i in range(max_hearts):
		var heart = TextureRect.new()
		heart.texture = heart_full
		
		heart.custom_minimum_size = Vector2(32, 32) # heart size
		heart.expand = true
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		container.add_child(heart)

	player.health_changed.connect(update_hearts)
	

func update_hearts(current_health):

	for i in range(container.get_child_count()):
		var heart = container.get_child(i)

		if i < current_health:
			heart.texture = heart_full
		else:
			heart.texture = heart_empty

	if current_health <= 0:
		pass
		#get_tree().paused = true
		
		# Instantiate GameOver Scene
		#var game_over_scene = load("res://Scenes/game_over.tscn")
		#var game_over = game_over_scene.instantiate()
		
		# Add it to the current scene so reloading works properly
		#get_tree().current_scene.add_child(game_over)
