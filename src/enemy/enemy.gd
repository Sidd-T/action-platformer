class_name Enemy
extends CharacterBody2D
## Punching-bag enemy: has health and armor, takes knockback, can be grabbed and thrown.
##
## Scene layout:
##   Enemy (CharacterBody2D, this script; collision mask = world only)
##   ├─ CollisionShape2D
##   ├─ Visual (any CanvasItem: Polygon2D, ColorRect, Sprite2D...)
##   ├─ Hurtbox (Area2D, hurtbox.gd) └─ CollisionShape2D
##   ├─ HealthLabel (Label, optional, for testing)
##   └─ StateMachine (target_node = Enemy, default_state = IdleState)
##      ├─ IdleState (EnemyIdleState)
##      ├─ HitstunState (EnemyHitstunState)
##      ├─ HeldState (EnemyHeldState)
##      └─ DeadState (EnemyDeadState)

signal health_changed(current: float, maximum: float)
signal died

@export var max_health: float = 100.0
## Flat damage reduction applied to every hit.
@export var armor: float = 0.0
## A damaging hit always deals at least this much, however high the armor is.
@export var min_damage: float = 1.0

@export_group("Physics")
@export var gravity: float = 1800.0
@export var gravity_limit: float = 1200.0
@export var ground_friction: float = 1500.0

@export_group("States")
@export var respawn_time: float = 3.0
## Safety net: a held enemy is released after this long even if never thrown.
@export var max_hold_time: float = 1.0

var health: float

# Read by EnemyHitstunState when it starts or restarts.
var pending_knockback: Vector2
var pending_hitstun: float

@onready var state_machine: StateMachine = $StateMachine as StateMachine
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var visual: Sprite2D = $Visual as Sprite2D
@onready var health_label: Label = get_node_or_null("HealthLabel") as Label
@onready var _spawn_position: Vector2 = global_position

func _ready() -> void:
	health = max_health
	_update_label()

func is_dead() -> bool:
	return health <= 0.0

func is_held() -> bool:
	return state_machine.active_state is EnemyHeldState

## Returns true if the hit was accepted.
func receive_hit(hit: HitData, _attacker: Node2D, facing: float) -> bool:
	if is_dead() or is_held():
		return false
	
	var damage: float = 0.0 if hit.damage <= 0.0 else maxf(hit.damage - armor, min_damage)
	health = maxf(health - damage, 0.0)
	health_changed.emit(health, max_health)
	_update_label()
	
	if is_dead():
		died.emit()
		state_machine.activate_state_by_name("DeadState")
	elif hit.throw_data:
		state_machine.activate_state_by_name("HeldState")
	else:
		apply_knockback(hit.get_knockback(facing), hit.hitstun_time)
	
	return true

func apply_knockback(knockback: Vector2, hitstun: float) -> void:
	pending_knockback = knockback
	pending_hitstun = hitstun
	
	var hitstun_state: EnemyHitstunState = state_machine.active_state as EnemyHitstunState
	
	if hitstun_state:
		hitstun_state.restart()
	else:
		state_machine.activate_state_by_name("HitstunState")

func respawn() -> void:
	if not is_dead():
		return
	
	global_position = _spawn_position
	velocity = Vector2.ZERO
	health = max_health
	health_changed.emit(health, max_health)
	_update_label()
	
	state_machine.activate_state_by_name("IdleState")

func apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, gravity_limit)

func apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_friction * delta)

func _update_label() -> void:
	if health_label:
		health_label.text = "%d / %d" % [ceili(health), ceili(max_health)]
