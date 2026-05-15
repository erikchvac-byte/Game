extends Node

const HOTBAR_SLOTS := 12   # 0 = bucket (reserved), 1..11 = usable
const GRID_SLOTS := 36
const MAX_STACK := 16

signal slot_changed(index: int, item: Variant)

class ItemEntry:
	var key: String
	var tex: Texture2D
	var count: int
	func _init(k: String, t: Texture2D) -> void:
		key = k
		tex = t
		count = 1

var _slots: Array = []


func _ready() -> void:
	_slots.resize(HOTBAR_SLOTS + GRID_SLOTS)


func add_item(key: String, tex: Texture2D) -> bool:
	# Stack into existing hotbar slot first
	for i in range(1, HOTBAR_SLOTS):
		var item: ItemEntry = _slots[i]
		if item != null and item.key == key and item.count < MAX_STACK:
			item.count += 1
			slot_changed.emit(i, item)
			return true
	# Open hotbar slot
	for i in range(1, HOTBAR_SLOTS):
		if _slots[i] == null:
			_slots[i] = ItemEntry.new(key, tex)
			slot_changed.emit(i, _slots[i])
			return true
	# Stack into existing grid slot
	var off := HOTBAR_SLOTS
	for i in range(GRID_SLOTS):
		var item: ItemEntry = _slots[off + i]
		if item != null and item.key == key and item.count < MAX_STACK:
			item.count += 1
			slot_changed.emit(off + i, item)
			return true
	# Open grid slot
	for i in range(GRID_SLOTS):
		if _slots[off + i] == null:
			_slots[off + i] = ItemEntry.new(key, tex)
			slot_changed.emit(off + i, _slots[off + i])
			return true
	return false


func remove_item(key: String) -> bool:
	for i in range(1, HOTBAR_SLOTS):
		var item = _slots[i]
		if item != null and item.key == key:
			item.count -= 1
			if item.count <= 0:
				_slots[i] = null
				slot_changed.emit(i, null)
			else:
				slot_changed.emit(i, item)
			return true
	var off := HOTBAR_SLOTS
	for i in range(GRID_SLOTS):
		var item = _slots[off + i]
		if item != null and item.key == key:
			item.count -= 1
			if item.count <= 0:
				_slots[off + i] = null
				slot_changed.emit(off + i, null)
			else:
				slot_changed.emit(off + i, item)
			return true
	return false


func has_item(key: String) -> bool:
	for i in range(1, HOTBAR_SLOTS + GRID_SLOTS):
		var item = _slots[i]
		if item != null and item.key == key:
			return true
	return false


func get_slot(index: int) -> Variant:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]
