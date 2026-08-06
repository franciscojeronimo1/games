class_name AutoPilot
extends RefCounted

## Decide movimento, mira e skills do player em modo automático.
## Prioridade: não deixar cercar → manter distância → atirar.

const PREFERRED_RANGE := 280.0
const MIN_SAFE_DIST := 220.0
const DANGER_RADIUS := 200.0
const PANIC_RADIUS := 140.0
const FLEE_BLEND_RADIUS := 280.0
const SURROUND_CHECK_RADIUS := 260.0
const ESCAPE_SAMPLES := 20


static func think(player: Player) -> Dictionary:
	var result := {
		"move": Vector2.ZERO,
		"aim": Vector2.RIGHT,
		"shoot": false,
		"dash": false,
		"dash_dir": Vector2.ZERO,
		"use_q": false,
		"use_e": false,
		"q_center": Vector2.ZERO,
	}

	var enemies := _alive_enemies(player)
	var closest: Node2D = null
	var closest_dist := INF
	var near_count := 0
	var panic_count := 0

	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e
		if d <= DANGER_RADIUS:
			near_count += 1
		if d <= PANIC_RADIUS:
			panic_count += 1

	var surrounded := _is_surrounded(player, enemies)
	var escape_dir := _best_escape_dir(player, enemies)

	var target := _pick_target(player, enemies)
	if target:
		result["aim"] = (target.global_position - player.global_position).normalized()
	elif closest:
		result["aim"] = (closest.global_position - player.global_position).normalized()
	else:
		result["aim"] = Vector2.RIGHT if not player.anim.flip_h else Vector2.LEFT

	# --- Movimento: sobrevivência primeiro ---
	if surrounded or panic_count >= 2 or closest_dist < PANIC_RADIUS:
		# Encurralado / colado: foge pelo melhor buraco e dasha
		result["move"] = escape_dir
		result["dash"] = true
		result["dash_dir"] = escape_dir
	elif near_count >= 2 or closest_dist < DANGER_RADIUS:
		# Zona de perigo: mistura fuga média + melhor buraco
		var flee_avg := _flee_vector(player, enemies)
		if flee_avg != Vector2.ZERO:
			result["move"] = (flee_avg * 0.45 + escape_dir * 0.55).normalized()
		else:
			result["move"] = escape_dir
		# Dash preventivo se muitos perto ou HP baixo
		if near_count >= 3 or closest_dist < MIN_SAFE_DIST or player.hp <= 2:
			result["dash"] = true
			result["dash_dir"] = result["move"]
	elif target:
		result["move"] = _kite_move(player, target, enemies)
	elif closest and closest_dist < MIN_SAFE_DIST:
		result["move"] = escape_dir
	else:
		var loot := _find_nearest_loot(player)
		if loot and (closest == null or closest_dist > DANGER_RADIUS + 60.0):
			var to_loot: Vector2 = loot.global_position - player.global_position
			result["move"] = to_loot.normalized()
			if closest:
				result["aim"] = (closest.global_position - player.global_position).normalized()
			else:
				result["aim"] = result["move"]

	# Atira enquanto foge (não para de matar no panic)
	if target and closest_dist < PREFERRED_RANGE + 160.0:
		result["shoot"] = true
	elif closest and closest_dist < PREFERRED_RANGE + 120.0:
		result["shoot"] = true

	# Skills de emergência quando cercado
	if player.has_bomb and (near_count >= 3 or surrounded or panic_count >= 2):
		result["use_e"] = true

	if player.has_arrow_rain and (target or closest):
		var focus: Node2D = target if target else closest
		var cluster := _count_near(focus.global_position, enemies, 150.0)
		if cluster >= 3 or surrounded or focus.is_in_group("boss") or focus.is_in_group("elites"):
			result["use_q"] = true
			result["q_center"] = focus.global_position

	return result


## Amostra várias direções e escolhe a com menos inimigos na frente (melhor “buraco”).
static func _best_escape_dir(player: Player, enemies: Array) -> Vector2:
	var best_dir := Vector2.RIGHT
	var best_score := -INF
	var momentum := Vector2.ZERO
	if player.velocity.length() > 20.0:
		momentum = player.velocity.normalized()

	for i in ESCAPE_SAMPLES:
		var dir := Vector2.from_angle(float(i) * TAU / float(ESCAPE_SAMPLES))
		var score := 0.0

		for e in enemies:
			var to_e: Vector2 = e.global_position - player.global_position
			var dist: float = to_e.length()
			if dist < 1.0 or dist > FLEE_BLEND_RADIUS + 40.0:
				continue
			var ahead: float = to_e.normalized().dot(dir)
			if ahead > 0.05:
				# Penaliza forte inimigo na direção de fuga
				var proximity := 1.0 / maxf(dist, 24.0)
				score -= ahead * ahead * proximity * 420.0
			else:
				# Inimigo atrás = bom (estamos saindo do círculo)
				score += (0.35 - ahead) * 8.0

		# Prefere manter momentum (menos “travar” trocando de lado)
		if momentum != Vector2.ZERO:
			score += momentum.dot(dir) * 22.0

		if score > best_score:
			best_score = score
			best_dir = dir

	return best_dir


## True se inimigos ocupam vários lados ao redor do player.
static func _is_surrounded(player: Player, enemies: Array) -> bool:
	var sectors: Array[bool] = [false, false, false, false, false, false, false, false]
	var in_range := 0
	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d > SURROUND_CHECK_RADIUS:
			continue
		in_range += 1
		var ang: float = (e.global_position - player.global_position).angle()
		var idx := int(floor((ang + PI) / TAU * 8.0)) % 8
		sectors[idx] = true

	if in_range < 3:
		return false

	var filled := 0
	for s in sectors:
		if s:
			filled += 1
	# 4+ setores = meio círculo ou mais ocupado → encurralado
	return filled >= 4


static func _kite_move(player: Player, target: Node2D, enemies: Array) -> Vector2:
	var to_target: Vector2 = target.global_position - player.global_position
	var dist: float = to_target.length()
	if dist < 0.001:
		return _best_escape_dir(player, enemies)

	var dir: Vector2 = to_target / dist

	if dist < MIN_SAFE_DIST:
		return _best_escape_dir(player, enemies)

	if dist <= PREFERRED_RANGE + 50.0:
		# Orbita pro lado que tem menos inimigos
		var left := dir.orthogonal()
		var right := -left
		var left_score := _direction_clearance(player, enemies, left)
		var right_score := _direction_clearance(player, enemies, right)
		var strafe := left if left_score >= right_score else right
		if dist < PREFERRED_RANGE - 30.0:
			return (-dir * 0.7 + strafe * 0.3).normalized()
		return strafe

	# Longe: aproxima com cuidado, desviando de packs
	var approach := (dir * 0.5 + _best_escape_dir(player, enemies) * 0.2).normalized()
	return approach


static func _direction_clearance(player: Player, enemies: Array, dir: Vector2) -> float:
	var score := 100.0
	for e in enemies:
		var to_e: Vector2 = e.global_position - player.global_position
		var dist: float = to_e.length()
		if dist < 1.0 or dist > DANGER_RADIUS + 80.0:
			continue
		var ahead: float = to_e.normalized().dot(dir)
		if ahead > 0.2:
			score -= ahead * (220.0 / maxf(dist, 30.0))
	return score


static func _flee_vector(player: Player, enemies: Array) -> Vector2:
	var flee := Vector2.ZERO
	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		if d > FLEE_BLEND_RADIUS or d < 1.0:
			continue
		var away: Vector2 = (player.global_position - e.global_position).normalized()
		var weight: float = 1.0 - (d / FLEE_BLEND_RADIUS)
		# Mais peso nos mais próximos
		weight *= weight
		flee += away * weight

	if flee.length() < 0.01:
		return Vector2.ZERO
	return flee.normalized()


static func _alive_enemies(player: Player) -> Array:
	var list: Array = []
	for node in player.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Node2D:
			list.append(node)
	return list


static func _pick_target(player: Player, enemies: Array) -> Node2D:
	var best: Node2D = null
	var best_score := -INF
	for e in enemies:
		var d: float = player.global_position.distance_to(e.global_position)
		var score := 1000.0 - absf(d - PREFERRED_RANGE)
		if d < MIN_SAFE_DIST:
			score -= 500.0
		if e is Boss or e.is_in_group("boss"):
			score += 600.0
		elif e.is_in_group("elites"):
			score += 250.0
		if score > best_score:
			best_score = score
			best = e
	return best


static func _count_near(origin: Vector2, enemies: Array, radius: float) -> int:
	var n := 0
	for e in enemies:
		if origin.distance_to(e.global_position) <= radius:
			n += 1
	return n


static func _find_nearest_loot(player: Player) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for node in player.get_tree().get_nodes_in_group("chest"):
		if not is_instance_valid(node) or not (node is Node2D):
			continue
		var d: float = player.global_position.distance_to(node.global_position)
		if d < best_d:
			best_d = d
			best = node
	return best
