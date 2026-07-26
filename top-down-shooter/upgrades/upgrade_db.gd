class_name UpgradeDB

const POOL := [
	{
		"id": "hp",
		"title": "Vitalidade",
		"desc": "+2 de vida máxima e atual",
		"unique": false,
	},
	{
		"id": "speed",
		"title": "Agilidade",
		"desc": "+50 de velocidade de movimento",
		"unique": false,
	},
	{
		"id": "firerate",
		"title": "Gatilho Rápido",
		"desc": "Atira um pouco mais rápido",
		"unique": false,
	},
	{
		"id": "damage",
		"title": "Pontas Afiadas",
		"desc": "+1 de dano nas flechas",
		"unique": false,
	},
	{
		"id": "double_shot",
		"title": "Tiro Duplo",
		"desc": "Dispara duas flechas em leque\nSinergia: + Traseiro = CRUZ",
		"unique": true,
	},
	{
		"id": "reverse_shot",
		"title": "Tiro Traseiro",
		"desc": "Também dispara para trás\nSinergia: + Duplo = CRUZ",
		"unique": true,
	},
	{
		"id": "pierce",
		"title": "Penetração",
		"desc": "Flechas atravessam inimigos\nSinergia: + Explosiva = cadeia",
		"unique": true,
	},
	{
		"id": "explosive",
		"title": "Flecha Explosiva",
		"desc": "Flechas explodem em área\nSinergia: + Penetração = cadeia",
		"unique": true,
	},
	{
		"id": "magnet",
		"title": "Ímã Arcano",
		"desc": "Puxa XP de longe automaticamente",
		"unique": true,
	},
	{
		"id": "arrow_rain",
		"title": "Chuva de Flechas",
		"desc": "Habilidade [Q]: chuva em área (CD)",
		"unique": true,
	},
	{
		"id": "bomb",
		"title": "Bomba de Choque",
		"desc": "Habilidade [E]: explosão perto de você (CD)",
		"unique": true,
	},
]


static func roll_three(player: Player) -> Array:
	var available: Array = []
	for upgrade in POOL:
		if upgrade["unique"] and player.has_upgrade(upgrade["id"]):
			continue
		if upgrade["id"] == "firerate" and player.shoot_coldown <= 0.12:
			continue
		available.append(upgrade)

	available.shuffle()
	var count := mini(3, available.size())
	return available.slice(0, count)


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
			player.magnet_radius = 320.0
		"arrow_rain":
			player.has_arrow_rain = true
		"bomb":
			player.has_bomb = true
