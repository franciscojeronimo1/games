extends Control




func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "animInicio":
		get_tree().change_scene_to_file("res://mapa/interior.tscn")
