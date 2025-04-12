extends Area2D

@export var speed = 600
var direction = Vector2.ZERO

func ready():
	$TrailParticles.emitting = true
	$Sprite2D.rotation = direction.angle()
	$CollisionShape2D.disabled = false
	connect("area_entered", Callable(self, "_on_area_entered"))

func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	position += direction * speed * delta

	# Auto-destruição fora da tela
	if not get_viewport_rect().has_point(global_position):
		queue_free()
