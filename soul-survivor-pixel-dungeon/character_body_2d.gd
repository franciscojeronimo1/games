extends CharacterBody2D

@export var speed := 200
@export var bullet_scene: PackedScene
@export var fire_rate := 0.3
@onready var fire_timer: Timer = $Timer

func _ready():
	fire_timer.wait_time = fire_rate
	fire_timer.one_shot = true

func _process(delta):
	look_at(get_global_mouse_position())

func _physics_process(delta):
	var direction := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): direction.x += 1
	if Input.is_action_pressed("ui_left"): direction.x -= 1
	if Input.is_action_pressed("ui_down"): direction.y += 1
	if Input.is_action_pressed("ui_up"): direction.y -= 1
	velocity = direction.normalized() * speed
	move_and_slide()
	
	if Input.is_action_just_pressed("attack_melee"):
		attack_melee()
		
	if Input.is_action_pressed("attack_shoot"):
		shoot()
		fire_timer.start()

func attack_melee():
	print("Espadada! (aqui você pode tocar um hitbox ou animação)")

func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	bullet.direction = (get_global_mouse_position() - global_position).normalized()
	get_tree().current_scene.add_child(bullet)
