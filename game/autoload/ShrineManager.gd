extends Node

# Trust: 0-100. Higher trust = higher exchange success rate.
# Success rate: 55% base + 0.45% per trust point (100% at trust 100).
var trust: int = 0

# Exchange table: item_key → Array of possible reward {key, tex_path, count}
const EXCHANGE_TABLE := {
	"stone_pile": [
		{"key": "lumber", "tex": "res://assets/props/items/lumber.png", "count": 1},
	]
}

signal trust_changed(new_trust: int)
signal exchange_succeeded(item_key: String, rewards: Array)
signal exchange_failed(item_key: String)


func _ready() -> void:
	if Engine.has_meta("shrine_trust"):
		trust = Engine.get_meta("shrine_trust")


func attempt_exchange(item_key: String) -> bool:
	if not EXCHANGE_TABLE.has(item_key):
		return false
	var success_chance := 0.55 + trust * 0.0045
	if randf() > success_chance:
		exchange_failed.emit(item_key)
		return false
	var rewards: Array = EXCHANGE_TABLE[item_key]
	var inv_mgr := get_node_or_null("/root/InventoryManager")
	for reward in rewards:
		var tex := load(reward["tex"]) as Texture2D
		for _i in range(reward["count"]):
			if inv_mgr:
				inv_mgr.add_item(reward["key"], tex)
	_add_trust(5)
	exchange_succeeded.emit(item_key, rewards)
	return true


func _add_trust(amount: int) -> void:
	trust = mini(trust + amount, 100)
	Engine.set_meta("shrine_trust", trust)
	trust_changed.emit(trust)
