class_name WallJumpState
extends PlayerState

func _enter(_previous_state: State) -> void:
	player.stop_jump_timers()
	player.dash_allowed = true
	player.reset_air_jumps()

func _physics_update(delta: float) -> void:
	if player.try_attack():
		return

	player.apply_gravity(delta, 1.0, true)
	player.apply_movement(delta, player.wall_jumping_acc_time, player.calculate_wall_jumping_dec_time())
	player.try_wall_jump()
	player.try_double_jump()
	player.try_dash()
	player.try_corner_correction(delta)
	player.update_flip_h()
	player.apply_move_anim()
	player.update_shape_scale(delta)

	player.move_and_slide()

	if player.velocity.y >= 0:
		switch_to("FallState")
	if player.get_slide_collision_count() > 0:
		switch_to("JumpState")
