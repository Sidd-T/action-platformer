class_name MotionSegment
extends Resource
## Moves the player during an attack. Velocities are authored for a player facing RIGHT
## (x is mirrored by facing).
##
## SET_VELOCITY: holds the velocity from start_time to end_time (charges, flying moves).
## IMPULSE: sets the velocity once at start_time (uppercuts, hops); end_time is ignored.
## Only the ticked axes (affect_x / affect_y) are touched.

enum Mode { SET_VELOCITY, IMPULSE }

@export var mode: Mode = Mode.SET_VELOCITY
@export var start_time: float = 0.1
@export var end_time: float = 0.4
@export var velocity: Vector2 = Vector2(900.0, 0.0)
@export var affect_x: bool = true
@export var affect_y: bool = false
## Optional speed multiplier over the window (x = progress 0..1). Empty = constant speed.
@export var speed_curve: Curve
## Multiplies gravity while a SET_VELOCITY segment runs. Gravity is switched off entirely
## while a segment with affect_y runs.
@export var gravity_scale: float = 1.0

@export_group("Ending")
## Fraction of velocity kept (on the affected axes) when a SET_VELOCITY segment ends on its
## own, so a 900 px/s charge doesn't turn into a slingshot.
@export var end_velocity_kept: Vector2 = Vector2(0.25, 0.25)

@export_group("Interrupts")
## SET_VELOCITY only. The move stops (or never starts) once any hitbox of the attack connects.
@export var stop_on_hit: bool = true
## SET_VELOCITY only. The move stops when it runs into a wall in its direction of travel.
## (Floors and ceilings aren't checked.)
@export var stop_on_wall: bool = true
## Fraction of velocity kept (on the affected axes) when stopped by a hit or a wall.
@export var stop_velocity_kept: Vector2 = Vector2.ZERO

func get_speed_multiplier(time: float) -> float:
	var progress: float = clampf((time - start_time) / maxf(end_time - start_time, 0.0001), 0.0, 1.0)

	return speed_curve.sample_baked(progress) if speed_curve else 1.0
