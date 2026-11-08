class_name Hurtbox
extends Area2D
## Add as a child of an Enemy with a CollisionShape2D child.
## Collision setup: layer = the enemy hurtbox layer, mask = none, Monitoring off, Monitorable on.

@export var target: Enemy

func _ready() -> void:
	if not target:
		target = get_parent() as Enemy

## Returns true if the hit was accepted.
func receive_hit(hit: HitData, attacker: Node2D, facing: float) -> bool:
	return target != null and target.receive_hit(hit, attacker, facing)
