extends Area2D

## The Pit Keeper — Guardian of the Monster's Arena.
## Speaks differently depending on whether the player has faced (and lost to) the monster.

@export var npc_name: String = "Pit Keeper"

@onready var prompt_label: Label = $PromptLabel

var _player_in_range: bool = false
var _shield_given: bool = false   # tracks if we already gifted the shield this session

# ─── Dialogue: First Arrival (before fighting the monster) ────────────────
const FIRST_ARRIVAL_LINES: Array[Dictionary] = [
	{
		"speaker": "Pit Keeper",
		"text": "...So the young prince dares to stand before the pit."
	},
	{
		"speaker": "Pit Keeper",
		"text": "I have watched warriors, knights, and generals descend into that darkness below. None have returned whole."
	},
	{
		"speaker": "Pit Keeper",
		"text": "The Ancient — the one your father calls a monster — it breathes fire older than this kingdom. Iron burns to ash before it even strikes flesh."
	},
	{
		"speaker": "Pit Keeper",
		"text": "Take this. It is a Fire Resistant Shield, forged in the same eternal flame that guards this pit. It will not make you invincible... but it will buy you a breath when you need one most.",
	},
	{
		"speaker": "Pit Keeper",
		"text": "Now go, prince. Prove to the kingdom — and to yourself — that you are worthy of the crown you seek."
	},
]

# ─── Dialogue: After Defeat (player has died at least once) ───────────────
const AFTER_DEFEAT_LINES: Array[Dictionary] = [
	{
		"speaker": "Pit Keeper",
		"text": "You live. I am... surprised."
	},
	{
		"speaker": "Pit Keeper",
		"text": "Most men who descend into the pit do not have the fortune of returning — even in defeat. The Ancient showed you mercy, or perhaps... it is merely toying with you."
	},
	{
		"speaker": "Pit Keeper",
		"text": "You are not ready. Not yet. Your blade is too dull and your body too fragile."
	},
	{
		"speaker": "Pit Keeper",
		"text": "Listen carefully. To the east, deep in the wetstone sanctuaries high upon the cliffs, there lies a Blade Upgrade — a whetstone of ancient make. It will harden your strikes beyond what any common steel can achieve."
	},
	{
		"speaker": "Pit Keeper",
		"text": "And to the south, in the valley of the old healers, grow the rarest herbs — the ones alchemists have made into the legendary Health Potions. Seek them. Drink them before you descend."
	},
	{
		"speaker": "Pit Keeper",
		"text": "A king does not conquer by brute strength alone. He prepares. He learns. He returns stronger than when he fell."
	},
	{
		"speaker": "Pit Keeper",
		"text": "Go. Gather what you need. When you are ready — truly ready — come back to the pit. The crown of Karam awaits the worthy."
	},
]

# ─── Dialogue: Return Talk (after defeat, if player talks again without leaving) ─
const REMINDER_LINES: Array[Dictionary] = [
	{
		"speaker": "Pit Keeper",
		"text": "The path east leads to the whetstone sanctuaries. The path south leads to the healers' valley. Do not return to the pit until you have both."
	},
]


func _ready() -> void:
	add_to_group("npc")
	process_mode = PROCESS_MODE_ALWAYS
	if prompt_label:
		prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not _player_in_range:
		return
	var db := _get_dialogue_box()
	if db and db.is_open():
		return
	if Input.is_action_just_pressed("up"):
		_start_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func _start_dialogue() -> void:
	var db := _get_dialogue_box()
	if not db:
		return

	# Check Fighting Pit payment status
	if GameManager:
		if not GameManager.is_pit_access_unlocked():
			if GameManager.coins >= 10:
				GameManager.remove_coins(10)
				GameManager.unlock_pit_access()
				var payment_granted_lines: Array[Dictionary] = [
					{
						"speaker": npc_name,
						"text": "Ah, 10 coins! The entry toll is paid. The Fighting Pit portal is now unlocked for you. Step through when you are ready to face the monster!"
					}
				]
				db.start(payment_granted_lines)
				return
			else:
				var payment_needed_lines: Array[Dictionary] = [
					{
						"speaker": npc_name,
						"text": "Halt, traveller! Entry to the Fighting Pit costs 10 coins. You only have " + str(GameManager.coins) + " coins. Gather 10 coins and speak to me again!"
					}
				]
				db.start(payment_needed_lines)
				return

	var defeated: bool = GameManager.player_was_defeated if GameManager else false

	if not defeated:
		# === First meeting: give fire shield and send to the pit ===
		db.dialogue_ended.connect(_on_first_dialogue_ended, CONNECT_ONE_SHOT)
		db.start(FIRST_ARRIVAL_LINES)
	elif not _shield_given:
		# === First talk after defeat: full journey guidance ===
		_shield_given = true  # prevent repeating the long version
		db.start(AFTER_DEFEAT_LINES)
	else:
		# === Subsequent talks: short reminder ===
		db.start(REMINDER_LINES)

func _on_first_dialogue_ended() -> void:
	# Gift the Fire Shield immediately after the keeper's speech
	if GameManager and not GameManager.has_fire_shield:
		GameManager.has_fire_shield = true
		# Find the player and apply the shield
		var player = get_tree().get_first_node_in_group("player")
		if player and "has_fire_shield" in player:
			player.has_fire_shield = true
		print("[PitKeeper] Fire Shield granted to player.")
		# Hide the in-world pickup if it exists nearby
		var pickup := get_tree().get_first_node_in_group("fire_shield_pickup")
		if pickup:
			pickup.queue_free()

func _get_dialogue_box() -> Node:
	return get_tree().get_first_node_in_group("dialogue_box")
