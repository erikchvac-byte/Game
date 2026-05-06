extends Sprite2D

const TEXTURES := [
	preload("res://GameAssets/Objects/DryingRacks/rack_weed_1plant.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_weed_2plants.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_weed_3plants.png"),
]

var _count := 0

func _ready() -> void:
	texture = TEXTURES[0]

func add_plant() -> void:
	if _count >= 2:
		return
	_count += 1
	texture = TEXTURES[_count]
