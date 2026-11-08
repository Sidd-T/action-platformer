class_name EnemyState
extends State

var enemy: Enemy

func _state_machine_ready() -> void:
	if target_node is not Enemy:
		push_error("Enemy state '%s' target node isn't an enemy." % get_path())
		return
	
	enemy = target_node as Enemy
