class_name HitboxSegment
extends Resource
## One hitbox of an attack. It exists from start_time to end_time (seconds since the attack
## began) and interpolates its offset, size and rotation over that window, so it can start
## close to the player and spread out, or sweep through an arc.
## Everything is authored for a player facing RIGHT and mirrored automatically.
## Keep segments at least ~0.03s long (a physics tick is 1/60s) so they can't be skipped.

enum ShapeType { RECTANGLE, CIRCLE, CAPSULE }

@export var start_time: float = 0.08
@export var end_time: float = 0.18
@export var shape_type: ShapeType = ShapeType.RECTANGLE

@export_group("Transform")
## Position relative to the player's origin at the start and end of the window.
@export var offset_start: Vector2 = Vector2(36.0, 0.0)
@export var offset_end: Vector2 = Vector2(36.0, 0.0)
## RECTANGLE: width and height. CIRCLE: radius in x. CAPSULE: radius in x, total height in y.
@export var size_start: Vector2 = Vector2(40.0, 30.0)
@export var size_end: Vector2 = Vector2(40.0, 30.0)
@export_range(-360.0, 360.0, 0.1, "degrees") var rotation_start: float = 0.0
@export_range(-360.0, 360.0, 0.1, "degrees") var rotation_end: float = 0.0
## Optional easing for the start -> end interpolation (x = progress 0..1, y = weight 0..1).
@export var ease_curve: Curve

@export_group("Hit")
## Overrides the attack's default hit (for sweetspots / sourspots). Empty = use the attack's.
@export var hit: HitData
## An enemy is hit at most once per hit group per swing. Segments that share a group never
## double-hit (sweeps, or a sweetspot over a sourspot: when both touch on the same tick, the
## segment listed first wins). Give a segment its own group number for a separate extra hit.
@export var hit_group: int = 0

## 0..1 interpolation weight at the given time (seconds since the attack began).
func get_weight(time: float) -> float:
	var progress: float = clampf((time - start_time) / maxf(end_time - start_time, 0.0001), 0.0, 1.0)

	return ease_curve.sample_baked(progress) if ease_curve else progress
