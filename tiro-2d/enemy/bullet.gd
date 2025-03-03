extends Area2D


@onready var animated_sprite = $AnimatedSprite2D
@onready var player = get_parent().find_child("player")

var aceleration: Vector2 = Vector2.ZERO

var velocity: Vector2 = Vector2.ZERO

func _physics_process(delta):
	aceleration = (player.position - position).normalized() * 700
	
	velocity += aceleration * delta
	rotation = velocity.angle()
	
	velocity = velocity.limit_length(150)
	
	position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	queue_free()
