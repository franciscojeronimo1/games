extends Area2D

@export_category("Variables")
@export var _attack_damage: int = 2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	print(body)
	if body is BaseCharacter:
		body.update_health(_attack_damage)
		print("player toumou dano")
		
