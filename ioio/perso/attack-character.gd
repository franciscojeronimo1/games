extends Area2D
class_name Attack_character

@export_category("Objects")
@export var collision_shape = CollisionShape2D

@onready var attack_timer = $AttackTimer

@export_category("Variables")
@export var _attack_damage: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	print(body)
	if body is Enemy_base:
		body.update_health(_attack_damage)
		
func _input(event):
	if event.is_action_pressed("left_attack"):
		collision_shape.disabled = false
		return
	if collision_shape.disabled == false:
		collision_shape.disabled = true
