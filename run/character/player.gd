extends CharacterBody2D

class_name Player

@onready var anim: AnimatedSprite2D = $Anim

@export var SPEED = 200.0
@export var JUMP_VELOCITY = -250.0


func _physics_process(delta: float) -> void:
	animacao()
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		anim.play("jump")
	if velocity.y > 0 and not is_on_floor():  
		anim.play("fall")
	move_and_slide()
	apply_push_force()
	
func animacao():
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	if is_on_floor() and velocity.x == 0:
		anim.play("idle")
	elif is_on_floor() and velocity.x != 0:
		anim.play("run")
	if direction !=0:
		anim.flip_h = direction < 0

func apply_push_force():
	for objects in get_slide_collision_count():
		var collision = get_slide_collision(objects)
		if collision.get_collider() is Pushables:
			collision.get_collider().slide_object(-collision.get_normal())
			anim.play("push")
