class_name AttackData
extends Resource
## Everything about a single move, as a timeline. Hitboxes and player movement are lists of
## segments positioned on that timeline (seconds since the attack began).
## Phases are derived: before the first hitbox segment = startup, while any hitbox segment
## is live = active, afterwards = recovery.
## All directional values are authored for a player facing RIGHT and mirrored by facing.

@export var attack_name: StringName
## Length of the whole move. Automatically extended to cover the last segment.
@export var total_time: float = 0.4

@export_group("Hit")
## Used by every hitbox segment that doesn't have its own hit data.
@export var hit: HitData

@export_group("Segments")
## Order matters: when segments in the same hit group overlap an enemy on the same tick,
## the one listed first wins (list sweetspots first).
@export var hitbox_segments: Array[HitboxSegment] = []
@export var motion_segments: Array[MotionSegment] = []

@export_group("Base Motion")
## Multiplies the player's velocity when the attack begins (0 = kill momentum, 1 = keep it all).
@export var momentum_kept: Vector2 = Vector2.ONE
@export var gravity_scale: float = 1.0
## 0 = no horizontal control (the player decelerates), 1 = full control.
## Ignored while a motion segment with affect_x is running.
@export_range(0.0, 1.0) var h_control: float = 0.0
## Deceleration time used when h_control is 0.
@export var h_decel_time: float = 0.3

func get_total_time() -> float:
	var result: float = total_time

	for segment: HitboxSegment in hitbox_segments:
		if segment:
			result = maxf(result, segment.end_time)

	for segment: MotionSegment in motion_segments:
		if segment:
			result = maxf(result, segment.end_time)

	return result

func get_active_start() -> float:
	var result: float = INF

	for segment: HitboxSegment in hitbox_segments:
		if segment:
			result = minf(result, segment.start_time)

	return result if result != INF else get_total_time()

func get_active_end() -> float:
	var result: float = -INF

	for segment: HitboxSegment in hitbox_segments:
		if segment:
			result = maxf(result, segment.end_time)

	return result if result != -INF else get_total_time()
