extends CharacterBody2D


@export var speed = 100  # Velocidade do inimigo
@onready var player = null  # Referência ao jogador

func _ready():
	player = get_tree().root.get_node("res://Player/player.tscn")  # Substitua pelo caminho real até o nó do jogador

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
	if player:
		pursue_player(delta)
	move_and_slide()
func pursue_player(delta):
	# Calcula a direção até o jogador
	var direction = (player.global_position - global_position).normalized()
	
	velocity = direction * speed
	
