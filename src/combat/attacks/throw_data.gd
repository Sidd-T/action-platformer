class_name ThrowData
extends Resource
## Describes how a grab-type attack throws the enemy once the throw window ends.
## The throw itself deals no damage; the damage comes from the attack that grabbed.

## How long the player can still choose left/right after the grab connects.
@export var window_time: float = 0.25
@export var force: float = 600.0
## Angle when throwing to the right (Godot's y axis points down, so -45 is up-right).
## It is mirrored when throwing to the left.
@export_range(-180.0, 180.0, 0.1, "degrees") var angle: float = -30.0
@export var hitstun_time: float = 0.4

func get_velocity(throw_dir: float) -> Vector2:
	var dir: Vector2 = Vector2.from_angle(deg_to_rad(angle))
	dir.x *= signf(throw_dir)
	
	return dir * force
