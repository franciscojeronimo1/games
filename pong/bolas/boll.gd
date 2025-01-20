extends CharacterBody2D




# Variáveis para controlar a velocidade e direção da bola
var speed = 400

func _ready():
	# Define uma direção inicial aleatória
	randomize()
	velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed

func _physics_process(delta):
	# Move a bola
	var collision = move_and_collide(velocity * delta)

	# Verifica colisão
	if collision:
		# Gera uma nova direção aleatória ao colidir
		randomize()
		velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * speed
