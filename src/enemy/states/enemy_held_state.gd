class_name EnemyHeldState
extends EnemyState
## The enemy is frozen in place while the player's AttackState decides the throw.
## AttackState ends this state by calling enemy.apply_knockback().

var time_left: float

func _enter(_previous_state: State) -> void:
	enemy.velocity = Vector2.ZERO
	time_left = enemy.max_hold_time

func _physics_update(delta: float) -> void:
	time_left -= delta
	
	if time_left <= 0.0:
		switch_to("IdleState")
