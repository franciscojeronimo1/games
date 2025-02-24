extends Control




func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://interface/inicio.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://mapa/creditos.tscn")
