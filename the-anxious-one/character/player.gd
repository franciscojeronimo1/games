extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $sprite

@export var speed: float = 100.0


var last_direction = "idleCosta"  # Direção inicial (pode ser qualquer uma das suas animações)

func _physics_process(delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
		sprite.flip_h = false
		last_direction = "direita"
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
		sprite.flip_h = true
		last_direction = "direita"
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
		last_direction = "frente"
	elif Input.is_action_pressed("ui_up"):
		direction.y -= 1
		last_direction = "costa"
		
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed  # Define a velocidade com base na direção
		sprite.play(last_direction)  # Toca a animação correta
	else:
		velocity = Vector2.ZERO  # Para o movimento quando não há direção
		sprite.play("idleCosta")  # Para a animação, mantendo o último frame

	move_and_slide()
