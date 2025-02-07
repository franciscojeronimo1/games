extends Area2D
@export var player:CharacterBody2D
@onready var potion_life: Area2D = $"."


func _on_body_entered(body: Node2D) -> void:
	if body.name == "player":
		player.heal()
		potion_life.queue_free()

		
