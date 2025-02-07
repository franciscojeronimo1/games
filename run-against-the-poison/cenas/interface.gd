extends Control



func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://mapa/mapa.tscn")


func _on_button_2_pressed() -> void:
	get_tree().change_scene_to_file("res://cenas/creditos.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
