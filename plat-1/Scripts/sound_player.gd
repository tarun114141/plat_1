extends Node

## AutoLoad SoundPlayer Singleton for managing Background Music (BGM) across the game.
## Tracks supported: Main Menu, Home, Health Hunt, Wheatstone Hunt, Fighting Pit.

enum BGMTrack {
	NONE,
	MAIN_MENU,
	HOME,
	HEALTH_HUNT,
	WHEATSTONE_HUNT,
	FIGHTING_PIT
}

@export_group("BGM Audio Streams (Placeholders)")
## Main Menu background music placeholder
@export var main_menu_music: AudioStream
## Home / Village / Main Level background music placeholder
@export var home_music: AudioStream
## Health Hunt scene background music placeholder
@export var health_hunt_music: AudioStream
## Wheatstone (Wetstone) Hunt scene background music placeholder
@export var wheatstone_music: AudioStream
## Fighting Pit area / combat background music placeholder
@export var fighting_pit_music: AudioStream

@export_group("Settings")
## Default crossfade duration in seconds between music tracks
@export var default_fade_duration: float = 0.8
## Default volume level in dB (0.0 is full volume)
@export var bgm_volume_db: float = 0.0

@onready var audio_player_a: AudioStreamPlayer = $AudioStreamPlayerA
@onready var audio_player_b: AudioStreamPlayer = $AudioStreamPlayerB

var current_track: BGMTrack = BGMTrack.NONE
var current_player: AudioStreamPlayer = null
var fade_tween: Tween = null
var previous_scene_track: BGMTrack = BGMTrack.NONE

func _ready() -> void:
	# Ensure audio processing even when the game is paused
	process_mode = PROCESS_MODE_ALWAYS
	
	# Connect finished signals for automatic looping fallback
	if audio_player_a:
		audio_player_a.finished.connect(func(): _on_player_finished(audio_player_a))
	if audio_player_b:
		audio_player_b.finished.connect(func(): _on_player_finished(audio_player_b))
		
	# Listen for scene transitions in the scene tree
	get_tree().node_added.connect(_on_node_added)
	
	# Check current scene on startup
	call_deferred("_check_initial_scene")

func _check_initial_scene() -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		_auto_play_for_scene(current_scene.scene_file_path)

func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		_auto_play_for_scene(node.scene_file_path)

## Automatically determines and switches BGM based on scene path
func _auto_play_for_scene(scene_path: String) -> void:
	var path_lower = scene_path.to_lower()
	if path_lower.contains("main_menu"):
		play_main_menu()
	elif path_lower.contains("wetstone") or path_lower.contains("wheatstone"):
		play_wheatstone_hunt()
	elif path_lower.contains("health_hunt"):
		play_health_hunt()
	elif path_lower.contains("tutorial") or path_lower.contains("level") or path_lower.contains("test") or path_lower.contains("intro_cutscene"):
		play_home()

# Explicit Helper Methods for Scenes and Triggers

func play_main_menu(fade_duration: float = -1.0) -> void:
	play_bgm(BGMTrack.MAIN_MENU, fade_duration)

func play_home(fade_duration: float = -1.0) -> void:
	play_bgm(BGMTrack.HOME, fade_duration)

func play_health_hunt(fade_duration: float = -1.0) -> void:
	play_bgm(BGMTrack.HEALTH_HUNT, fade_duration)

func play_wheatstone_hunt(fade_duration: float = -1.0) -> void:
	play_bgm(BGMTrack.WHEATSTONE_HUNT, fade_duration)

func play_wetstone_hunt(fade_duration: float = -1.0) -> void:
	play_wheatstone_hunt(fade_duration)

func play_fighting_pit(fade_duration: float = -1.0) -> void:
	play_bgm(BGMTrack.FIGHTING_PIT, fade_duration)

## Helper function to play music by string name
func play_bgm_by_name(track_name: String, fade_duration: float = -1.0) -> void:
	match track_name.to_lower():
		"main_menu", "menu":
			play_main_menu(fade_duration)
		"home", "village", "level", "tutorial":
			play_home(fade_duration)
		"health_hunt", "health":
			play_health_hunt(fade_duration)
		"wheatstone", "wetstone", "wheatstone_hunt", "wetstone_hunt":
			play_wheatstone_hunt(fade_duration)
		"fighting_pit", "pit", "combat":
			play_fighting_pit(fade_duration)
		_:
			push_warning("SoundPlayer: Unknown track name '%s'" % track_name)

## Core transition logic to switch background music with smooth crossfading & looping
func play_bgm(track: BGMTrack, fade_duration: float = -1.0) -> void:
	if fade_duration < 0:
		fade_duration = default_fade_duration

	# If we are already playing this track, don't restart it
	if current_track == track and current_player != null and current_player.playing:
		return

	# Remember scene track when entering fighting pit so exiting pit can restore scene music
	if track != BGMTrack.FIGHTING_PIT:
		previous_scene_track = track

	current_track = track
	var stream: AudioStream = _get_stream_for_track(track)

	# Determine active and target players for crossfading
	var old_player: AudioStreamPlayer = current_player
	var new_player: AudioStreamPlayer = audio_player_b if old_player == audio_player_a else audio_player_a

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	if fade_duration > 0.05:
		fade_tween = create_tween().set_parallel(true)

		# Fade out old player if it is currently playing
		if old_player and old_player.playing:
			fade_tween.tween_property(old_player, "volume_db", -80.0, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			fade_tween.chain().tween_callback(old_player.stop)

		# Start and fade in new player if stream placeholder is assigned
		if stream != null:
			new_player.stream = stream
			new_player.volume_db = -80.0
			new_player.play()
			fade_tween.tween_property(new_player, "volume_db", bgm_volume_db, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			current_player = new_player
		else:
			current_player = null
	else:
		# Instant swap without fade duration
		if old_player and old_player.playing:
			old_player.stop()
		if stream != null:
			new_player.stream = stream
			new_player.volume_db = bgm_volume_db
			new_player.play()
			current_player = new_player
		else:
			current_player = null

## Stop all music with fade out
func stop_music(fade_duration: float = -1.0) -> void:
	if fade_duration < 0:
		fade_duration = default_fade_duration

	current_track = BGMTrack.NONE

	if fade_tween and fade_tween.is_running():
		fade_tween.kill()

	if current_player and current_player.playing:
		if fade_duration > 0.05:
			fade_tween = create_tween()
			fade_tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
			fade_tween.tween_callback(current_player.stop)
		else:
			current_player.stop()
		current_player = null

## Loop handling: ensures music replays automatically when it reaches the end
func _on_player_finished(player: AudioStreamPlayer) -> void:
	if player == current_player and current_track != BGMTrack.NONE:
		player.play(0.0)

## Restores the music active before entering temporary zones (like fighting pit)
func exit_fighting_pit(fade_duration: float = -1.0) -> void:
	if previous_scene_track != BGMTrack.NONE:
		play_bgm(previous_scene_track, fade_duration)
	else:
		play_home(fade_duration)

func _get_stream_for_track(track: BGMTrack) -> AudioStream:
	match track:
		BGMTrack.MAIN_MENU:
			return main_menu_music
		BGMTrack.HOME:
			return home_music
		BGMTrack.HEALTH_HUNT:
			return health_hunt_music
		BGMTrack.WHEATSTONE_HUNT:
			return wheatstone_music
		BGMTrack.FIGHTING_PIT:
			return fighting_pit_music
		_:
			return null
