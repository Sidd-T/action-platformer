class_name AttackState
extends PlayerState
## Runs one attack as a timeline driven by elapsed time: hitbox segments are posed and polled
## by the Hitbox, motion segments move the player. Art can later be played in sync with
## `elapsed`; gameplay never reads from animation.
## No cancels: the only ways out are finishing the move, or chaining a buffered attack/jump
## once it ends.

enum Phase { STARTUP, ACTIVE, RECOVERY }
enum MotionState { PENDING, RUNNING, DONE }

# Tint the shape per phase while there is no art: yellow = startup, red = active, blue = recovery.
const DEBUG_TINTS: Array[Color] = [Color.YELLOW, Color.RED, Color.CORNFLOWER_BLUE]

@export var debug_tint: bool = true

var attack: AttackData
var phase: Phase = Phase.STARTUP
var elapsed: float = 0.0

var _total_time: float = 0.0
var _active_start: float = 0.0
var _active_end: float = 0.0

var _motion_applied: bool = false
var _motion_states: Array[int] = []
var _gravity_scale: float = 1.0
var _x_locked: bool = false

var _held_enemy: Enemy
var _held_throw: ThrowData
var _throw_time_left: float = 0.0
var _throw_dir: float = 1.0

func _state_machine_ready() -> void:
	super()
	player.hitbox.hit_landed.connect(_on_hit_landed)

func _enter(_previous_state: State) -> void:
	player.stop_jump_timers()
	player.attack_buffer_timer.stop()

	_begin(player.current_attack)

func _exit(_next_state: State) -> void:
	_release_held()
	player.hitbox.end_swing()
	player.shape.modulate = Color.WHITE

func _physics_update(delta: float) -> void:
	# Buffer inputs for when the move ends.
	player.try_jump_buffer_timer()
	player.try_attack_buffer_timer()

	elapsed += delta

	# Applied on the first physics tick instead of in _enter, because the previous
	# state's _exit runs after this state's _enter and could overwrite it.
	if not _motion_applied:
		_motion_applied = true
		player.velocity *= attack.momentum_kept

	_track_throw_dir()
	_update_phase()
	player.hitbox.tick(elapsed) # May call _on_hit_landed, which can cancel motion.
	_update_motion()
	_apply_gravity_and_control(delta)
	_tick_held(delta)

	player.apply_move_anim()
	player.update_shape_scale(delta)

	player.move_and_slide()

	if elapsed >= _total_time:
		_finish()

func _begin(data: AttackData) -> void:
	attack = data
	elapsed = 0.0
	_motion_applied = false
	_throw_dir = player.get_facing_dir()

	_total_time = data.get_total_time()
	_active_start = data.get_active_start()
	_active_end = data.get_active_end()

	_motion_states.clear()
	_motion_states.resize(data.motion_segments.size())
	_motion_states.fill(MotionState.PENDING)

	player.hitbox.begin_swing(data, player.get_facing_dir())
	_set_phase(Phase.STARTUP)

func _update_phase() -> void:
	var new_phase: Phase = Phase.STARTUP

	if elapsed >= _active_end:
		new_phase = Phase.RECOVERY
	elif elapsed >= _active_start:
		new_phase = Phase.ACTIVE

	if new_phase != phase:
		_set_phase(new_phase)

func _set_phase(new_phase: Phase) -> void:
	phase = new_phase

	if debug_tint:
		player.shape.modulate = DEBUG_TINTS[phase]

# --- Player movement ---

func _update_motion() -> void:
	_gravity_scale = attack.gravity_scale
	_x_locked = false

	var facing: float = player.get_facing_dir()

	for i: int in attack.motion_segments.size():
		var segment: MotionSegment = attack.motion_segments[i]

		if not segment or _motion_states[i] == MotionState.DONE or elapsed < segment.start_time:
			continue

		if segment.mode == MotionSegment.Mode.IMPULSE:
			_set_velocity(segment, 1.0, facing)
			_motion_states[i] = MotionState.DONE
			continue

		if elapsed >= segment.end_time:
			# Taper off, but only if the segment actually ran.
			if _motion_states[i] == MotionState.RUNNING:
				_scale_velocity(segment, segment.end_velocity_kept)

			_motion_states[i] = MotionState.DONE
			continue

		if segment.stop_on_wall and _is_blocked_by_wall(segment, facing):
			_cancel_motion(i)
			continue

		_motion_states[i] = MotionState.RUNNING
		_set_velocity(segment, segment.get_speed_multiplier(elapsed), facing)

		_x_locked = _x_locked or segment.affect_x
		_gravity_scale *= 0.0 if segment.affect_y else segment.gravity_scale

func _apply_gravity_and_control(delta: float) -> void:
	# At zero scale gravity is skipped entirely, so its velocity clamp can't cut a fast flight short.
	if _gravity_scale > 0.0:
		player.apply_gravity(delta, _gravity_scale)

	if _x_locked:
		return

	if attack.h_control > 0.0:
		var on_floor: bool = player.is_on_floor()
		var acc_time: float = player.running_acc_time if on_floor else player.falling_acc_time
		var dec_time: float = player.running_dec_time if on_floor else player.falling_dec_time

		player.apply_movement(delta, acc_time / attack.h_control, dec_time / attack.h_control)
	else:
		player.apply_deceleration(delta, attack.h_decel_time)

func _set_velocity(segment: MotionSegment, multiplier: float, facing: float) -> void:
	if segment.affect_x:
		player.velocity.x = segment.velocity.x * facing * multiplier
	if segment.affect_y:
		player.velocity.y = segment.velocity.y * multiplier

func _scale_velocity(segment: MotionSegment, factor: Vector2) -> void:
	if segment.affect_x:
		player.velocity.x *= factor.x
	if segment.affect_y:
		player.velocity.y *= factor.y

func _cancel_motion(index: int) -> void:
	var segment: MotionSegment = attack.motion_segments[index]

	# A segment that never started has nothing to stop.
	if _motion_states[index] == MotionState.RUNNING:
		_scale_velocity(segment, segment.stop_velocity_kept)

	_motion_states[index] = MotionState.DONE

func _is_blocked_by_wall(segment: MotionSegment, facing: float) -> bool:
	if not segment.affect_x or not player.is_on_wall():
		return false

	# Only a wall in the direction of travel counts, not one the player is charging away from.
	return player.get_wall_normal().x * signf(segment.velocity.x) * facing < 0.0

# --- Finishing ---

func _finish() -> void:
	# Resolve any pending throw before leaving.
	_release_held()

	var on_floor: bool = player.is_on_floor()

	# Buffered jump: a normal jump on the ground, a double jump in the air (if one is left).
	# Without an air jump the buffer is left for landing.
	if not player.jump_buffer_timer.is_stopped():
		if on_floor:
			player.try_buffer_jump()
			switch_to("AirEntryState")
			return
		elif player.can_double_jump():
			player.double_jump()
			switch_to("AirEntryState")
			return

	# Buffered attack: chain straight into the next one.
	if not player.attack_buffer_timer.is_stopped():
		player.attack_buffer_timer.stop()

		var next_attack: AttackData = player.pick_attack(player.buffered_heavy)

		if next_attack:
			player.current_attack = next_attack
			_begin(next_attack)
			return

	switch_to("FloorEntryState" if on_floor else "AirEntryState")

# --- Hits and throws ---

func _on_hit_landed(target: Enemy, hit: HitData) -> void:
	if not is_active():
		return

	# Connecting stops (or cancels the start of) every motion that asks for it.
	for i: int in attack.motion_segments.size():
		var segment: MotionSegment = attack.motion_segments[i]

		if (segment and segment.mode == MotionSegment.Mode.SET_VELOCITY
			and segment.stop_on_hit and _motion_states[i] != MotionState.DONE
		):
			_cancel_motion(i)

	if hit.throw_data and target.is_held():
		_held_enemy = target
		_held_throw = hit.throw_data
		_throw_time_left = hit.throw_data.window_time

func _track_throw_dir() -> void:
	# The last left/right pressed (from the start of the attack until the throw
	# window ends) decides the direction. Defaults to the facing direction.
	var h_input: float = signf(player.get_input_vector().x)

	if h_input:
		_throw_dir = h_input

func _tick_held(delta: float) -> void:
	if not _held_enemy:
		return

	_throw_time_left -= delta

	if _throw_time_left <= 0.0:
		_release_held()

func _release_held() -> void:
	if not _held_enemy:
		return

	var enemy: Enemy = _held_enemy
	var throw: ThrowData = _held_throw

	_held_enemy = null
	_held_throw = null

	if is_instance_valid(enemy) and enemy.is_held():
		enemy.apply_knockback(throw.get_velocity(_throw_dir), throw.hitstun_time)
