class_name JumpState
extends PlayerState

func _enter(_previous_state: State) -> void:
	player.stop_jump_timers()

func _physics_update(delta: float) -> void:
	if player.try_attack():
		return

	player.apply_gravity(delta, 1.0, true)
	player.apply_movement(delta, player.jumping_acc_time, player.jumping_dec_time)
	player.try_wall_jump()
	player.try_coyote_wall_jump()
	player.try_wall_jump_buffer_timer()
	player.try_double_jump()
	player.try_dash()
	player.try_corner_correction(delta)
	player.update_flip_h()
	player.apply_move_anim()
	player.update_shape_scale(delta)

	player.move_and_slide()

	if player.velocity.y >= 0:
		switch_to("FallState")
