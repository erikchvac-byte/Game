extends Node2D

# Fay Grove — the ShT quietly exchanges items left at the stump.
# Drop an item in the grove radius (Q key), step away, return after ~10s.
# 40% chance: processed version. 60% chance: double raw. Never nothing.
# One trade at a time.

const GROVE_RADIUS  := 60.0   # detection area around stump
const PROCESS_TIME  := 10.0   # seconds for ShT to process the offering

# item_key → {processed: [key, tex_path], raw: [key, tex_path, count]}
const EXCHANGE_TABLE := {
	"bud": {
		"processed": ["bud", "res://assets/props/bud/hang_dry.png"],
		"raw":       ["bud", "res://assets/props/bud/dry_bud.png", 2],
	},
	"stone_pile": {
		"processed": ["lumber",     "res://assets/props/items/lumber.png"],
		"raw":       ["stone_pile", "res://assets/props/items/stone_pile.png", 2],
	},
	"wood": {
		"processed": ["lumber", "res://assets/props/items/lumber.png"],
		"raw":       ["wood",   "res://assets/props/items/wood_pile.png", 2],
	},
	"hang_dry": {
		"processed": ["gem_ruby",  "res://assets/props/items/gem_ruby.png"],
		"raw":       ["hang_dry",  "res://assets/props/bud/hang_dry.png", 2],
	},
	"lumber": {
		"processed": ["ingot_copper_01", "res://assets/props/items/ingot_copper_01.png"],
		"raw":       ["lumber",          "res://assets/props/items/lumber.png", 2],
	},
}

enum State { IDLE, ITEM_PRESENT, PROCESSING, REWARD_READY, REWARD_SPAWNED }

var _state           := State.IDLE
var _player          : Node2D
var _stump_home      : AnimatedSprite2D
var _player_in_grove := false
var _pending_item    : Node    = null
var _captured_key    := ""
var _captured_pos    := Vector2.ZERO
var _process_timer   := 0.0
var _pulse_t         := 0.0
var _reward_key      := ""
var _reward_tex_path := ""
var _reward_count    := 1
var _reward_item     : Node    = null


func _ready() -> void:
	add_to_group("shrine")
	call_deferred("_cache_player")


func _cache_player() -> void:
	_player = get_parent().get_node_or_null("Player") as Node2D
	_stump_home = get_parent().get_node_or_null("StumpHome001") as AnimatedSprite2D


func _process(delta: float) -> void:
	if not _player:
		_player = get_parent().get_node_or_null("Player") as Node2D
		return

	_player_in_grove = _player.global_position.distance_to(global_position) < GROVE_RADIUS

	match _state:
		State.IDLE:
			_scan_for_drop()

		State.ITEM_PRESENT:
			if not is_instance_valid(_pending_item):
				_state = State.IDLE
				return
			if not _player_in_grove:
				# Player stepped away — ShT takes the offering
				_pending_item.queue_free()
				_pending_item = null
				_calculate_reward()
				_process_timer = PROCESS_TIME
				_pulse_t = 0.0
				_state = State.PROCESSING
				_show_toast("Something stirs in the grove...", 2.5)
				if _stump_home and _stump_home.sprite_frames.has_animation(&"door_open"):
					_stump_home.play(&"door_open")
					_stump_home.animation_finished.connect(_on_door_anim_finished, CONNECT_ONE_SHOT)

		State.PROCESSING:
			_process_timer -= delta
			_pulse_t += delta
			var pulse := (sin(_pulse_t * 2.5) + 1.0) * 0.5
			if _stump_home:
				_stump_home.modulate = Color(1.0, 0.85 + 0.15 * pulse, 0.6 + 0.2 * pulse, 1.0)
			if _process_timer <= 0.0:
				if _stump_home:
					_stump_home.modulate = Color.WHITE
				# Spawn reward immediately regardless of player position
				_spawn_reward()
				_state = State.REWARD_SPAWNED

		State.REWARD_SPAWNED:
			if not is_instance_valid(_reward_item):
				_state = State.IDLE
				return
			if _player_in_grove:
				# Auto-collect when player re-enters the grove
				_grant_reward()


func _scan_for_drop() -> void:
	for item in get_tree().get_nodes_in_group("world_drop_items"):
		var item_node := item as Node2D
		if item_node == null or not is_instance_valid(item_node):
			continue
		if item_node.has_meta("grove_reward"):
			continue
		if item_node.global_position.distance_to(global_position) >= GROVE_RADIUS:
			continue
		var key: String = item_node.get("item_key") as String
		if EXCHANGE_TABLE.has(key):
			_pending_item  = item_node
			_captured_key  = key
			_captured_pos  = item_node.position
			_state = State.ITEM_PRESENT
			return


func _calculate_reward() -> void:
	var entry: Dictionary = EXCHANGE_TABLE[_captured_key]
	if randf() < 0.40:
		var p: Array = entry["processed"]
		_reward_key      = p[0]
		_reward_tex_path = p[1]
		_reward_count    = 1
	else:
		var r: Array = entry["raw"]
		_reward_key      = r[0]
		_reward_tex_path = r[1]
		_reward_count    = r[2]


func _spawn_reward() -> void:
	var drop_scene := preload("res://World/WorldDropItem/world_drop_item.tscn")
	var drop := drop_scene.instantiate() as Node2D
	drop.set_meta("item_key", _reward_key)
	drop.set_meta("item_tex", load(_reward_tex_path) as Texture2D)
	drop.set_meta("grove_reward", true)
	drop.set_meta("despawn_time", 120.0)
	drop.position = _captured_pos
	get_parent().add_child(drop)
	_reward_item = drop


func _grant_reward() -> void:
	var inv := get_node_or_null("/root/InventoryManager")
	var tex  := load(_reward_tex_path) as Texture2D
	for _i in range(_reward_count):
		if inv:
			inv.add_item(_reward_key, tex)
	if is_instance_valid(_reward_item):
		_reward_item.queue_free()
	_reward_item    = null
	_show_toast("The grove returned your offering...", 3.0)
	_state         = State.IDLE
	_captured_key  = ""
	_reward_key    = ""
	_reward_count  = 1


func _on_door_anim_finished() -> void:
	if _stump_home and _stump_home.sprite_frames.has_animation(&"idle"):
		_stump_home.play(&"idle")


func _show_toast(msg: String, duration: float) -> void:
	var hud := get_node_or_null("/root/HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(msg, duration)
