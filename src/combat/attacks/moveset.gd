class_name Moveset
extends Resource
## Maps (ground/air, light/heavy, direction) to an AttackData.
## Side attacks are mirrored by facing, so there is no separate left/right move.

enum Dir { NEUTRAL, SIDE, DOWN }

@export_group("Ground Light")
@export var ground_light_neutral: AttackData
@export var ground_light_side: AttackData
@export var ground_light_down: AttackData

@export_group("Ground Heavy")
@export var ground_heavy_neutral: AttackData
@export var ground_heavy_side: AttackData
@export var ground_heavy_down: AttackData

@export_group("Air Light")
@export var air_light_neutral: AttackData
@export var air_light_side: AttackData
@export var air_light_down: AttackData

@export_group("Air Heavy")
@export var air_heavy_neutral: AttackData
@export var air_heavy_side: AttackData
@export var air_heavy_down: AttackData

func get_attack(on_ground: bool, heavy: bool, dir: Dir) -> AttackData:
	if on_ground:
		if heavy:
			return [ground_heavy_neutral, ground_heavy_side, ground_heavy_down][dir]
		return [ground_light_neutral, ground_light_side, ground_light_down][dir]
	
	if heavy:
		return [air_heavy_neutral, air_heavy_side, air_heavy_down][dir]
	return [air_light_neutral, air_light_side, air_light_down][dir]
