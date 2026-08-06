class_name UpgradeDB

const POOL := [
	{
		"id": "hp",
		"title": "Vitalidade",
		"desc": "+2 de vida máxima e atual",
		"unique": false,
		"weight": 10,
	},
	{
		"id": "speed",
		"title": "Agilidade",
		"desc": "+50 de velocidade de movimento",
		"unique": false,
		"weight": 10,
	},
	{
		"id": "firerate",
		"title": "Gatilho Rápido",
		"desc": "Atira um pouco mais rápido",
		"unique": false,
		"weight": 10,
	},
	{
		"id": "damage",
		"title": "Pontas Afiadas",
		"desc": "+1 de dano nas flechas",
		"unique": false,
		"weight": 10,
	},
	{
		"id": "double_shot",
		"title": "Tiro Duplo",
		"desc": "Dispara duas flechas em leque\nSinergia: + Traseiro = CRUZ",
		"unique": true,
		"weight": 6,
	},
	{
		"id": "reverse_shot",
		"title": "Tiro Traseiro",
		"desc": "Também dispara para trás\nSinergia: + Duplo = CRUZ",
		"unique": true,
		"weight": 6,
	},
	{
		"id": "pierce",
		"title": "Penetração",
		"desc": "Flechas atravessam inimigos\nSinergia: + Explosiva = cadeia",
		"unique": true,
		"weight": 5,
	},
	{
		"id": "explosive",
		"title": "Flecha Explosiva",
		"desc": "Flechas explodem em área\nSinergia: + Penetração = cadeia",
		"unique": true,
		"weight": 5,
	},
	{
		"id": "magnet",
		"title": "Bolso Furado",
		"desc": "Ganha +1 moeda a cada kill",
		"unique": true,
		"weight": 6,
	},
	{
		"id": "arrow_rain",
		"title": "Chuva de Flechas",
		"desc": "Habilidade [Q]: chuva em área (CD)",
		"unique": true,
		"weight": 4,
	},
	{
		"id": "bomb",
		"title": "Bomba de Choque",
		"desc": "Habilidade [E]: explosão perto de você (CD)",
		"unique": true,
		"weight": 4,
	},
	{
		"id": "foot_trail",
		"title": "Trilha Tóxica",
		"desc": "Deixa rastros venenosos ao andar.\nInimigos que pisam levam dano",
		"unique": true,
		"weight": 2,
	},
	{
		"id": "fire_arrow",
		"title": "Ataque de Fogo",
		"desc": "Projéteis inflamam inimigos\n(dano contínuo / queimadura)",
		"unique": true,
		"weight": 3,
	},
	{
		"id": "fire_burn_time",
		"title": "Chama Persistente",
		"desc": "Queimadura dura +1.2s",
		"unique": false,
		"weight": 4,
		"requires_element": "fire",
	},
	{
		"id": "fire_burn_dmg",
		"title": "Brasa Afiada",
		"desc": "+1 de dano por tick da queimadura",
		"unique": false,
		"weight": 4,
		"requires_element": "fire",
	},
	{
		"id": "ice_arrow",
		"title": "Ataque de Gelo",
		"desc": "Congela o alvo e deixa\ninimigos próximos mais lentos",
		"unique": true,
		"weight": 3,
	},
	{
		"id": "ice_slow_power",
		"title": "Geada Profunda",
		"desc": "Slow mais forte e +0.8s de duração",
		"unique": false,
		"weight": 4,
		"requires_element": "ice",
	},
	{
		"id": "ice_aura",
		"title": "Nevasca",
		"desc": "+40 de raio do frio em área",
		"unique": false,
		"weight": 3,
		"requires_element": "ice",
	},
]


static func roll_three(player: Player) -> Array:
	var available: Array = []
	var cid := SkillNames.char_id(player)
	for upgrade in POOL:
		if upgrade["unique"] and player.has_upgrade(upgrade["id"]):
			continue
		if upgrade["id"] == "firerate" and player.shoot_coldown <= 0.12:
			continue
		var req: String = str(upgrade.get("requires_element", ""))
		if req != "" and player.arrow_element != req:
			continue
		if upgrade["id"] == "fire_arrow" and player.arrow_element != "normal":
			continue
		if upgrade["id"] == "ice_arrow" and player.arrow_element != "normal":
			continue
		if upgrade["id"] == "fire_burn_time" and player.burn_duration >= 6.0:
			continue
		if upgrade["id"] == "fire_burn_dmg" and player.burn_damage >= 5:
			continue
		if upgrade["id"] == "ice_slow_power" and player.ice_slow_mult <= 0.25:
			continue
		if upgrade["id"] == "ice_aura" and player.ice_aura_radius >= 180.0:
			continue
		available.append(SkillNames.localize_upgrade(upgrade, cid))

	var picks: Array = []
	for _i in 3:
		if available.is_empty():
			break
		var chosen: Dictionary = _weighted_pick(available)
		picks.append(chosen)
		available.erase(chosen)
	return picks


static func _weighted_pick(pool: Array) -> Dictionary:
	var total := 0
	for item in pool:
		total += int(item.get("weight", 10))
	var roll := randi_range(1, maxi(1, total))
	var acc := 0
	for item in pool:
		acc += int(item.get("weight", 10))
		if roll <= acc:
			return item
	return pool[pool.size() - 1]


static func apply(player: Player, upgrade_id: String) -> void:
	match upgrade_id:
		"hp":
			player.max_hp += 2
			player.hp = mini(player.hp + 2, player.max_hp)
		"speed":
			player.move_speed += 50.0
		"firerate":
			player.shoot_coldown = maxf(0.12, player.shoot_coldown * 0.82)
		"damage":
			player.bullet_damage += 1
		"double_shot":
			player.has_double_shot = true
		"reverse_shot":
			player.has_reverse_shot = true
		"pierce":
			player.has_pierce = true
		"explosive":
			player.has_explosive = true
		"magnet":
			player.has_magnet = true
			player.bonus_coins_per_kill = 1
		"arrow_rain":
			player.has_arrow_rain = true
		"bomb":
			player.has_bomb = true
		"foot_trail":
			player.has_foot_trail = true
		"fire_arrow":
			player.arrow_element = "fire"
		"fire_burn_time":
			player.burn_duration += 1.2
		"fire_burn_dmg":
			player.burn_damage += 1
		"ice_arrow":
			player.arrow_element = "ice"
		"ice_slow_power":
			player.ice_slow_mult = maxf(0.22, player.ice_slow_mult - 0.1)
			player.ice_slow_duration += 0.8
		"ice_aura":
			player.ice_aura_radius += 40.0
