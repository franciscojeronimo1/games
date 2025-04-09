extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
@onready var enemy: CharacterBody2D = $"../Enemy"
@export var summoned_scene: PackedScene
@export var summon_distance: float = 50  # Distância do summon na frente do player

@export var hp = 10
@onready var player: CharacterBody2D = $"."


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()


func _process(delta):
	if Input.is_action_just_pressed("summon_action"):
		summon()

func summon():
	if summoned_scene:
		var instance = summoned_scene.instantiate()
		var direction = Vector2.RIGHT if $Sprite2D.flip_h else Vector2.LEFT
		instance.position = global_position + (direction * summon_distance)
		get_parent().add_child(instance)  # Adiciona à cena atual
	else:
		print("Erro: Cena de summon não definida")


func _on_vida_body_entered(body: Node2D) -> void:
	if body.is_in_group('Enemy'):
		player.queue_free()
		print(hp)
