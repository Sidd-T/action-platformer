class_name HitData
extends Resource
## What happens to an enemy when a hitbox connects: damage, knockback, or a throw.
## Directional values are authored for a player facing RIGHT and mirrored by facing.

## Damage before the enemy's armor is subtracted. Use 0 for a damage-free grab.
@export var damage: float = 10.0
@export var hitstun_time: float = 0.3
@export var knockback_force: float = 400.0
## Y axis points down, so -45 is up-right. Ignored when throw_data is set.
@export_range(-180.0, 180.0, 0.1, "degrees") var knockback_angle: float = -30.0
## If set, this hit grabs the enemy and the player can throw it (see ThrowData) instead of knocking it back.
@export var throw_data: ThrowData

func get_knockback(facing: float) -> Vector2:
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(knockback_angle))
	dir.x *= signf(facing)

	return dir * knockback_force
