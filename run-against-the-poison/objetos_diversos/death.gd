extends Area2D

@onready var player: Player = $"../player"


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player.dead()
