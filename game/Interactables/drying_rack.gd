extends Sprite2D

const TEXTURES := [
	preload("res://GameAssets/Objects/DryingRacks/rack_new_empty.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_3plants.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_2plants.png"),
	preload("res://GameAssets/Objects/DryingRacks/rack_new_1plant.png"),
]

var _count := 0

func _ready() -> void:
	texture = TEXTURES[0]

func add_plant() -> void:
	if _count >= 3:
		return
	_count += 1
	texture = TEXTURES[_count]
