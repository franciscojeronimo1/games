extends CharacterBody2D

@export var speed := 100
@export var max_health := 3
var health := max_health
@onready var player: CharacterBody2D = $"."


func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()

func take_damage(amount):
	health -= amount
	if health <= 0:
		die()

func die():
	queue_free()
	print("Inimigo derrotado!")
