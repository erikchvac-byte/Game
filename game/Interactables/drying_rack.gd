extends Sprite2D

const TEXTURES := [
	preload("res://GameAssets/Objects/DryingRacks/rack_new_empty.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_3plants.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_2plants.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_1plant.png"),
]
const PRODUCTS := [
	preload("res://GameAssets/Objects/herb_bundle_dried.png"),
	preload("res://GameAssets/Bud/hang_dry.png"),
	preload("res://GameAssets/Bud/plant_green.png"),
	preload("res://GameAssets/Bud/plant_green_2.png"),
	preload("res://GameAssets/Bud/plant_purple.png"),
	preload("res://GameAssets/Bud/weed_plant.png"),
	preload("res://GameAssets/Bud/weed_plant_2.png"),
	preload("res://GameAssets/Bud/dry_bud.png"),
]
const DRY_DURATION := 5.0
const READY_DURATION := 1.5

enum State { EMPTY, FILLING, DRYING, READY }

var _count := 0
var _state := State.EMPTY
var _timer := 0.0


func _ready() -> void:
	texture = TEXTURES[0]
	set_process(false)


func _process(delta: float) -> void:
	_timer -= delta
	if _state == State.DRYING:
		if _timer <= 0.0:
			_state = State.READY
			_timer = READY_DURATION
	elif _state == State.READY:
		var t: float = Time.get_ticks_msec() * 0.004
		modulate = Color(1.0, 0.85 + 0.15 * sin(t), 0.4 + 0.4 * sin(t + 1.0), 1.0)
		if _timer <= 0.0:
			_award_and_reset()


func add_plant() -> void:
	if _state != State.EMPTY and _state != State.FILLING:
		return
	_count += 1
	texture = TEXTURES[_count]
	if _count < 3:
		_state = State.FILLING
	else:
		_state = State.DRYING
		_timer = DRY_DURATION
		set_process(true)


func _award_and_reset() -> void:
	var inv := get_node_or_null("/root/Inventory")
	if inv and inv.has_method("add_item"):
		inv.add_item("bud", PRODUCTS[randi() % PRODUCTS.size()])
	_count = 0
	_state = State.EMPTY
	_timer = 0.0
	texture = TEXTURES[0]
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	set_process(false)
