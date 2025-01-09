extends Area2D

@export var hp: int = 5
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	print(body)
	if body is Area2D:
		print("tomei dano")
