extends Area2D





func _on_body_entered(body: Node2D) -> void:
	if body == RigidBody2D:
		position.y =  randf()
