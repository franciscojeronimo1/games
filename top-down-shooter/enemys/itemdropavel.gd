extends Area2D





func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		await get_tree().create_timer(0.1).timeout
		queue_free()
