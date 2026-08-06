extends Area2D

@export var speed: float = 900.0
@export var dmg: int = 1
@export var pierce: bool = false
@export var explosive: bool = false
@export var chain_explode: bool = false
@export var explosion_radius: float = 90.0
## Bolas mágicas ficam melhores sem rotacionar com a direção
@export var rotate_with_direction: bool = true

## "normal" | "fire" | "ice"
var element: String = "normal"
var burn_damage: int = 1
var burn_duration: float = 2.5
var burn_tick: float = 0.5
var ice_slow_mult: float = 0.45
var ice_slow_duration: float = 2.0
var ice_aura_radius: float = 95.0

var direction: Vector2 = Vector2.ZERO
var _hit_enemies: Array = []
var _trail_fx: GPUParticles2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_apply_visuals()


func _process(delta: float) -> void:
	position += direction * speed * delta


func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	if rotate_with_direction:
		rotation = direction.angle()
	else:
		# Bola fica reta; só o rastro acompanha a direção do tiro
		rotation = 0.0
		if sprite:
			sprite.rotation = 0.0
		_orient_trail()


func configure(damage: int, can_pierce: bool, can_explode: bool, extras: Dictionary = {}) -> void:
	dmg = damage
	pierce = can_pierce
	explosive = can_explode
	chain_explode = can_pierce and can_explode

	element = str(extras.get("element", "normal"))
	burn_damage = int(extras.get("burn_damage", 1))
	burn_duration = float(extras.get("burn_duration", 2.5))
	burn_tick = float(extras.get("burn_tick", 0.5))
	ice_slow_mult = float(extras.get("ice_slow_mult", 0.45))
	ice_slow_duration = float(extras.get("ice_slow_duration", 2.0))
	ice_aura_radius = float(extras.get("ice_aura_radius", 95.0))

	if chain_explode:
		modulate = Color(1.0, 0.25, 1.0)
		explosion_radius = 110.0
	elif explosive and element == "normal":
		modulate = Color(1.0, 0.55, 0.2)
	else:
		modulate = Color.WHITE

	_apply_visuals()


func _apply_visuals() -> void:
	if sprite and sprite.sprite_frames:
		match element:
			"fire":
				if sprite.sprite_frames.has_animation("attack-fogo"):
					sprite.play("attack-fogo")
			"ice":
				if sprite.sprite_frames.has_animation("attack-gelo"):
					sprite.play("attack-gelo")
			_:
				if sprite.sprite_frames.has_animation("attack-normal"):
					sprite.play("attack-normal")
	_setup_trail_particles()


func _setup_trail_particles() -> void:
	if _trail_fx and is_instance_valid(_trail_fx):
		_trail_fx.queue_free()
		_trail_fx = null

	if element != "fire" and element != "ice":
		return

	_trail_fx = GPUParticles2D.new()
	_trail_fx.z_index = -1
	_trail_fx.amount = 22
	_trail_fx.lifetime = 0.32
	_trail_fx.preprocess = 0.12
	_trail_fx.explosiveness = 0.0
	_trail_fx.local_coords = true
	_trail_fx.emitting = true

	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	# Sai no -X local; o nó do rastro é rotacionado pra ficar atrás do tiro
	mat.direction = Vector3(-1, 0, 0)
	mat.spread = 22.0
	mat.initial_velocity_min = 22.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, 0, 0)
	mat.scale_min = 1.2
	mat.scale_max = 2.6
	mat.damping_min = 10.0
	mat.damping_max = 22.0

	if element == "fire":
		mat.color = Color(1.0, 0.45, 0.1, 0.95)
		mat.hue_variation_min = -0.04
		mat.hue_variation_max = 0.06
	else:
		mat.color = Color(0.65, 0.92, 1.0, 0.9)
		mat.scale_min = 1.0
		mat.scale_max = 2.2

	_trail_fx.process_material = mat
	add_child(_trail_fx)
	_orient_trail()


## Rastro sempre atrás do projétil.
func _orient_trail() -> void:
	if _trail_fx == null or not is_instance_valid(_trail_fx):
		return
	if rotate_with_direction:
		# O próprio bullet já aponta na direção do tiro
		_trail_fx.position = Vector2(-6, 0)
		_trail_fx.rotation = 0.0
		return
	if direction == Vector2.ZERO:
		_trail_fx.position = Vector2(-6, 0)
		_trail_fx.rotation = 0.0
		return
	# Bola sem rotação: gira só o emissor do rastro
	_trail_fx.position = -direction * 6.0
	_trail_fx.rotation = direction.angle()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return
	if body in _hit_enemies:
		return

	_hit_enemies.append(body)
	_apply_hit(body)

	if explosive:
		_explode_at(global_position)
		if chain_explode and pierce:
			return
		queue_free()
		return

	if pierce:
		return

	queue_free()


func _apply_hit(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(dmg, global_position)

	match element:
		"fire":
			if body.has_method("apply_burn"):
				body.apply_burn(burn_damage, burn_duration, burn_tick)
			_spawn_hit_burst(body.global_position, true)
		"ice":
			_apply_ice_aura(body.global_position)
			_spawn_hit_burst(body.global_position, false)


func _apply_ice_aura(origin: Vector2) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if origin.distance_to(node.global_position) > ice_aura_radius:
			continue
		if node.has_method("apply_slow"):
			# Alvo direto fica mais lento; ao redor um pouco menos
			var mult := ice_slow_mult
			if origin.distance_to(node.global_position) > 8.0:
				mult = clampf(ice_slow_mult + 0.15, 0.2, 0.85)
			node.apply_slow(mult, ice_slow_duration)


func _spawn_hit_burst(at: Vector2, is_fire: bool) -> void:
	var burst := GPUParticles2D.new()
	burst.global_position = at
	burst.z_index = 8
	burst.amount = 16
	burst.lifetime = 0.35
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 4.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 110.0
	mat.gravity = Vector3(0, 80 if is_fire else 120, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.5
	mat.color = Color(1.0, 0.45, 0.1, 1.0) if is_fire else Color(0.7, 0.95, 1.0, 1.0)
	burst.process_material = mat
	var scene := get_tree().current_scene
	if scene:
		scene.add_child(burst)
		burst.finished.connect(burst.queue_free)
		# Fallback se finished não disparar
		burst.get_tree().create_timer(0.6, true).timeout.connect(func() -> void:
			if is_instance_valid(burst):
				burst.queue_free()
		)


func _explode_at(origin: Vector2) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node):
			continue
		if node in _hit_enemies:
			continue
		if origin.distance_to(node.global_position) <= explosion_radius:
			_hit_enemies.append(node)
			_apply_hit(node)
