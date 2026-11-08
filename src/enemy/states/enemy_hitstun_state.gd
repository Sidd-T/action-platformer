class_name EnemyHitstunState
extends EnemyState

var time_left: float

func _enter(_previous_state: State) -> void:
	restart()

## Called again when the enemy is hit during hitstun (combos).
func restart() -> void:
	enemy.velocity = enemy.pending_knockback
	time_left = enemy.pending_hitstun

func _physics_update(delta: float) -> void:
	enemy.apply_gravity(delta)
	
	# Friction only when sliding along the floor, not while being launched off it.
	if enemy.is_on_floor() and enemy.velocity.y >= 0.0:
		enemy.apply_friction(delta)
	
	enemy.move_and_slide()
	
	time_left -= delta
	
	if time_left <= 0.0:
		switch_to("IdleState")
