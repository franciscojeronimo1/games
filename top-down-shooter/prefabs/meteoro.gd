extends Area2D
## Meteoro do mago: cai de cima no alvo e explode em área grande.

@export var speed: float = 780.0
@export var dmg: int = 12
@export var explosion_radius: float = 230.0
@export var fall_height: float = 480.0
@export var rotate_with_direction: bool = true

## Direção “pra frente” da sprite (pedra na frente, fogo atrás).
## Nesta arte: pedra embaixo-esquerda, cauda em cima-direita → voa pra baixo-esquerda.
const ART_FORWARD := Vector2(-1.0, 1.0)

var target_pos: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.DOWN
var _exploded: bool = false
var _apply_burn: bool = true
var burn_damage: int = 1
var burn_duration: float = 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack-fogo"):
		sprite.play("attack-fogo")
	_update_facing()


func setup(impact: Vector2, damage: int, radius: float = 230.0, from_height: float = -1.0) -> void:
	target_pos = impact
	dmg = maxi(1, damage)
	explosion_radius = radius
	var height := fall_height if from_height < 0.0 else from_height
	global_position = impact + Vector2(randf_range(-28.0, 28.0), -height)
	direction = (target_pos - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	_update_facing()


func _update_facing() -> void:
	if not rotate_with_direction:
		rotation = 0.0
		return
	# Compensa o ângulo em que a sprite foi desenhada
	rotation = direction.angle() - ART_FORWARD.angle()


func _process(delta: float) -> void:
	if _exploded:
		return
	global_position += direction * speed * delta
	# Chegou no chão / ponto de impacto
	if global_position.distance_to(target_pos) <= 22.0 or global_position.y >= target_pos.y:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if _exploded:
		return
	if body.is_in_group("enemies"):
		# Não altera physics flags dentro do sinal — agenda a explosão
		call_deferred("_explode")


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	set_process(false)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if sprite:
		sprite.visible = false

	var origin := target_pos if target_pos != Vector2.ZERO else global_position
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if origin.distance_to(node.global_position) > explosion_radius:
			continue
		if node.has_method("take_damage"):
			node.take_damage(dmg, origin)
		if _apply_burn and node.has_method("apply_burn"):
			node.apply_burn(burn_damage, burn_duration, 0.45)
		if node.has_method("apply_knockback"):
			var push: Vector2 = (node.global_position - origin).normalized()
			if push == Vector2.ZERO:
				push = Vector2.RIGHT
			node.apply_knockback(push * 640.0)

	_spawn_explosion_vfx(origin)
	await get_tree().create_timer(0.35, true).timeout
	queue_free()


func _spawn_explosion_vfx(origin: Vector2) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var ring := Polygon2D.new()
	ring.z_index = 30
	ring.color = Color(1.0, 0.45, 0.1, 0.8)
	var pts := PackedVector2Array()
	for i in 28:
		var a := float(i) * TAU / 28.0
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	ring.polygon = pts
	ring.global_position = origin
	scene.add_child(ring)

	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * (explosion_radius / 20.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(ring.queue_free)

	var burst := GPUParticles2D.new()
	burst.z_index = 31
	burst.global_position = origin
	burst.amount = 48
	burst.lifetime = 0.45
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 10.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 120.0
	mat.initial_velocity_max = 320.0
	mat.gravity = Vector3(0, 220, 0)
	mat.scale_min = 2.5
	mat.scale_max = 5.5
	mat.color = Color(1.0, 0.55, 0.12, 1.0)
	burst.process_material = mat
	scene.add_child(burst)
	burst.get_tree().create_timer(0.8, true).timeout.connect(func() -> void:
		if is_instance_valid(burst):
			burst.queue_free()
	)
