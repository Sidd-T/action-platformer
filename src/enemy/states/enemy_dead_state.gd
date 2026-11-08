class_name EnemyDeadState
extends EnemyState
## Dead enemies can't be hit and respawn after enemy.respawn_time (handy for testing).

func _enter(_previous_state: State) -> void:
	enemy.hurtbox.set_deferred("monitorable", false)
	enemy.visual.modulate.a = 0.3
	enemy.get_tree().create_timer(enemy.respawn_time).timeout.connect(enemy.respawn)

func _exit(_next_state: State) -> void:
	enemy.hurtbox.set_deferred("monitorable", true)
	enemy.visual.modulate.a = 1.0

func _physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	
	if enemy.is_on_floor():
		enemy.apply_friction(delta)
	
	enemy.move_and_slide()
