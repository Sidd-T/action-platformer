class_name Hitbox
extends Node2D
## The player's attack hitboxes. Add as a direct child of Player (NOT under Shape, so
## squash/stretch/skew can't distort it). It needs no children: it creates one Area2D per
## hitbox segment at runtime, then moves, resizes and polls them every physics tick.
## Debug > Visible Collision Shapes shows them while the game runs.

signal hit_landed(target: Enemy, hit: HitData)

## Physics layers that count as enemy hurtboxes (default: layer 4).
@export_flags_2d_physics var hurtbox_mask: int = 8

class Slot:
	var area: Area2D
	var shape_node: CollisionShape2D
	var live: bool = false

var attack: AttackData

var _facing: float = 1.0
var _slots: Array[Slot] = []
var _hit_log: Dictionary = {} # hit_group (int) -> Array of Hurtbox already hit this swing
var _throw_landed: bool = false

func begin_swing(data: AttackData, facing: float) -> void:
	end_swing()

	attack = data
	_facing = facing
	_hit_log.clear()
	_throw_landed = false

	for segment: HitboxSegment in data.hitbox_segments:
		if segment and not segment.hit and not data.hit:
			push_warning("Attack '%s' has a hitbox segment with no hit data and no default hit." % data.attack_name)
			break

func end_swing() -> void:
	attack = null

	for slot: Slot in _slots:
		_set_live(slot, false)

## Call once per physics tick with the seconds since the attack began.
func tick(time: float) -> void:
	if not attack:
		return

	var count: int = attack.hitbox_segments.size()

	for i: int in count:
		var segment: HitboxSegment = attack.hitbox_segments[i]
		var slot: Slot = _get_slot(i)
		var live: bool = segment != null and time >= segment.start_time and time < segment.end_time

		_set_live(slot, live)

		if live:
			_pose(slot, segment, time)

	# Slots left over from an earlier attack with more segments stay off.
	for i: int in range(count, _slots.size()):
		_set_live(_slots[i], false)

	_check_hits()

func _check_hits() -> void:
	var attacker: Node2D = get_parent() as Node2D

	for i: int in attack.hitbox_segments.size():
		var segment: HitboxSegment = attack.hitbox_segments[i]
		var slot: Slot = _slots[i]

		if not slot.live:
			continue

		var hit: HitData = segment.hit if segment.hit else attack.hit

		if not hit:
			continue

		for area: Area2D in slot.area.get_overlapping_areas():
			var hurtbox: Hurtbox = area as Hurtbox

			if not hurtbox:
				continue

			# A throw-type hit only grabs one enemy per swing.
			if hit.throw_data and _throw_landed:
				break

			var hit_list: Array = _hit_log.get_or_add(segment.hit_group, [])

			if hurtbox in hit_list:
				continue

			if hurtbox.receive_hit(hit, attacker, _facing):
				hit_list.append(hurtbox)

				if hit.throw_data:
					_throw_landed = true

				hit_landed.emit(hurtbox.target, hit)

				if not attack:
					return

func _set_live(slot: Slot, live: bool) -> void:
	if slot.live == live:
		return

	slot.live = live
	slot.area.monitoring = live

func _get_slot(index: int) -> Slot:
	while _slots.size() <= index:
		var slot: Slot = Slot.new()

		slot.area = Area2D.new()
		slot.area.name = "Slot%d" % _slots.size()
		slot.area.collision_layer = 0
		slot.area.collision_mask = hurtbox_mask
		slot.area.monitorable = false
		slot.area.monitoring = false

		slot.shape_node = CollisionShape2D.new()
		slot.area.add_child(slot.shape_node)
		add_child(slot.area)

		_slots.append(slot)

	return _slots[index]

func _pose(slot: Slot, segment: HitboxSegment, time: float) -> void:
	var weight: float = segment.get_weight(time)
	var offset: Vector2 = segment.offset_start.lerp(segment.offset_end, weight)

	slot.area.position = Vector2(offset.x * _facing, offset.y)
	slot.area.rotation_degrees = lerpf(segment.rotation_start, segment.rotation_end, weight) * _facing

	_apply_size(slot, segment.shape_type, segment.size_start.lerp(segment.size_end, weight))

func _apply_size(slot: Slot, shape_type: HitboxSegment.ShapeType, size: Vector2) -> void:
	match shape_type:
		HitboxSegment.ShapeType.CIRCLE:
			var circle: CircleShape2D = slot.shape_node.shape as CircleShape2D

			if not circle:
				circle = CircleShape2D.new()
				slot.shape_node.shape = circle

			circle.radius = maxf(size.x, 0.1)

		HitboxSegment.ShapeType.CAPSULE:
			var capsule: CapsuleShape2D = slot.shape_node.shape as CapsuleShape2D

			if not capsule:
				capsule = CapsuleShape2D.new()
				slot.shape_node.shape = capsule

			var radius: float = maxf(size.x, 0.1)

			capsule.height = maxf(size.y, radius * 2.0)
			capsule.radius = radius

		_:
			var rect: RectangleShape2D = slot.shape_node.shape as RectangleShape2D

			if not rect:
				rect = RectangleShape2D.new()
				slot.shape_node.shape = rect

			rect.size = Vector2(maxf(size.x, 0.1), maxf(size.y, 0.1))
