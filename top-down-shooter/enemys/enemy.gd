extends CharacterBody2D

@export var move_speed: float = 100.0
@export var health : int = 5
@onready var anim: AnimatedSprite2D = $anim
@export var drop : PackedScene
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D

var direction : Vector2 = Vector2.ZERO
var player = null
var original_color := Color.WHITE
var knockback_velocity : Vector2 = Vector2.ZERO
var knockback_decay : float = 1000.0
@export var deathParticle : PackedScene



func spawn_enemy_item():
	var drop_instance = drop.instantiate()
	call_deferred("_add_drop", drop_instance)
	


func _add_drop(drop_instance):
	get_tree().current_scene.add_child(drop_instance)
	drop_instance.global_position = global_position
	
func _ready() -> void:
	player = Global.player
	original_color = anim.modulate

func _physics_process(delta: float) -> void:
	if knockback_velocity.length() > 1:
		velocity = knockback_velocity
		move_and_slide()
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)
	else:
		if player:
			direction = global_position.direction_to(player.global_position)
			velocity = direction * move_speed
		
	move_and_slide()

func hit_flash():
	anim.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	anim.modulate = original_color

func apply_knockback(force: Vector2):
	knockback_velocity = force
	
func take_damage(amount: int, source_position: Vector2):
	health -= amount
	var knockback_dir = (global_position - source_position).normalized()
	apply_knockback(knockback_dir * 300)
	hit_flash()

	if health <= 0:
		call_deferred("drop_and_die") # adia a morte e o drop para o próximo frame
		killParticle()
	print("Enemy health is: " + str(health))

func drop_and_die():
	spawn_enemy_item()
	queue_free()

func killParticle():
	var _particle = deathParticle.instantiate()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
	
	queue_free()
