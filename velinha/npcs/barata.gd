extends CharacterBody2D

@export var speed: float = 50  # Velocidade de movimento
@export var gravity: float = 800  # Gravidade
@export var detection_range: float = 200  # Distância para detectar o jogador
@onready var barata: CharacterBody2D = $"."


@onready var player = get_parent().find_child("player")  # Encontra o jogador na cena
@onready var sprite = $AnimatedSprite2D  # Referência ao sprite do inimigo

func _physics_process(delta):
	apply_gravity(delta)  # Aplica gravidade
	follow_player()  # Persegue o player
	move_and_slide()  # Move o inimigo

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta  # Aplica gravidade

func follow_player():
	if player == null:
		return  # Evita erro se o player não existir
		
	var direction = (player.position - position).normalized()  # Direção até o player
	var distance = position.distance_to(player.position)  # Distância ao player
	if distance <= detection_range:
		velocity.x = direction.x * speed  # Move na direção do player
		sprite.flip_h = velocity.x > 0  # Vira o sprite conforme a direção
	else:
		velocity.x = 0  # Para quando está longe do player


func _on_tomar_dmg_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		barata.queue_free()
