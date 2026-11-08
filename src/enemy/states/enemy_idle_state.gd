class_name EnemyIdleState
extends EnemyState

func _physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	
	if enemy.is_on_floor():
		enemy.apply_friction(delta)
	
	enemy.move_and_slide()
