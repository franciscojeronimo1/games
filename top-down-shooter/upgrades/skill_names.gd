class_name SkillNames

## Nomes por personagem. Futuros heróis: só adicionar a chave no mapa.

const ABILITY_Q := {
	"archer": "Chuva",
	"wizard": "Meteoros",
}

const ABILITY_E := {
	"archer": "Bomba",
	"wizard": "Nova",
}

const SYNERGY := {
	"archer": {
		"cross": "CRUZ",
		"chain": "CADEIA",
		"coins": "MOEDAS+",
		"trail": "TRILHA",
		"fire": "FOGO",
		"ice": "GELO",
	},
	"wizard": {
		"cross": "ESTRELA",
		"chain": "REAÇÃO",
		"coins": "MOEDAS+",
		"trail": "CÍRCULO",
		"fire": "INFERNO",
		"ice": "GEADA",
	},
}

## Overrides de upgrade: id -> personagem -> {title, desc}
## Se não tiver override, usa o title/desc padrão do UpgradeDB (arqueiro).
const UPGRADE_NAMES := {
	"firerate": {
		"wizard": {
			"title": "Canalização Rápida",
			"desc": "Lança feitiços um pouco mais rápido",
		},
	},
	"damage": {
		"wizard": {
			"title": "Núcleo Arcano",
			"desc": "+1 de dano nas bolas mágicas",
		},
	},
	"double_shot": {
		"wizard": {
			"title": "Orbe Duplo",
			"desc": "Dispara duas bolas em leque\nSinergia: + Eco = ESTRELA",
		},
	},
	"reverse_shot": {
		"wizard": {
			"title": "Eco Arcano",
			"desc": "Também dispara para trás\nSinergia: + Orbe Duplo = ESTRELA",
		},
	},
	"pierce": {
		"wizard": {
			"title": "Magia Penetrante",
			"desc": "Bolas atravessam inimigos\nSinergia: + Explosiva = REAÇÃO",
		},
	},
	"explosive": {
		"wizard": {
			"title": "Orbe Explosivo",
			"desc": "Bolas explodem em área\nSinergia: + Penetrante = REAÇÃO",
		},
	},
	"arrow_rain": {
		"wizard": {
			"title": "Chuva de Meteoros",
			"desc": "Habilidade [Q]: meteoros caem nos inimigos\ne explodem em área grande (CD)",
		},
	},
	"bomb": {
		"wizard": {
			"title": "Nova Arcana",
			"desc": "Habilidade [E]: explosão mágica perto de você (CD)",
		},
	},
	"foot_trail": {
		"wizard": {
			"title": "Círculo Tóxico",
			"desc": "Deixa um círculo venenoso ao andar.\nInimigos que pisam levam dano",
		},
	},
	"fire_arrow": {
		"archer": {
			"title": "Flecha de Fogo",
			"desc": "Flechas inflamam inimigos\n(dano contínuo / queimadura)",
		},
		"wizard": {
			"title": "Bola de Fogo",
			"desc": "Bolas inflamam inimigos\n(dano contínuo / queimadura)",
		},
	},
	"fire_burn_time": {
		"wizard": {
			"title": "Inferno Persistente",
			"desc": "Queimadura dura +1.2s",
		},
	},
	"fire_burn_dmg": {
		"wizard": {
			"title": "Brasa Arcana",
			"desc": "+1 de dano por tick da queimadura",
		},
	},
	"ice_arrow": {
		"archer": {
			"title": "Flecha de Gelo",
			"desc": "Congela o alvo e deixa\ninimigos próximos mais lentos",
		},
		"wizard": {
			"title": "Bola de Gelo",
			"desc": "Congela o alvo e deixa\ninimigos próximos mais lentos",
		},
	},
	"ice_slow_power": {
		"wizard": {
			"title": "Geada Arcana",
			"desc": "Slow mais forte e +0.8s de duração",
		},
	},
	"ice_aura": {
		"wizard": {
			"title": "Nevasca Mística",
			"desc": "+40 de raio do frio em área",
		},
	},
}

const DUKE_NAMES := {
	"power_pact": {
		"wizard": {"title": "Pacto Arcano"},
	},
	"lucky_shot": {
		"wizard": {"title": "Faísca da Sorte"},
	},
	"poison_trail": {
		"wizard": {"title": "Círculo Tóxico"},
	},
	"fire_arrow": {
		"archer": {"title": "Flecha de Fogo"},
		"wizard": {"title": "Bola de Fogo"},
	},
	"ice_arrow": {
		"archer": {"title": "Flecha de Gelo"},
		"wizard": {"title": "Bola de Gelo"},
	},
	"fire_fuel": {
		"wizard": {"title": "Óleo Arcano"},
	},
}


static func char_id(player: Player = null) -> String:
	if player != null and is_instance_valid(player):
		return str(player.character_id)
	if Global.player != null and is_instance_valid(Global.player):
		return str(Global.player.character_id)
	return str(Global.selected_character)


static func ability_q_name(character_id: String = "") -> String:
	if character_id.is_empty():
		character_id = char_id()
	return str(ABILITY_Q.get(character_id, ABILITY_Q["archer"]))


static func ability_e_name(character_id: String = "") -> String:
	if character_id.is_empty():
		character_id = char_id()
	return str(ABILITY_E.get(character_id, ABILITY_E["archer"]))


static func synergy_label(key: String, character_id: String = "") -> String:
	if character_id.is_empty():
		character_id = char_id()
	var table: Dictionary = SYNERGY.get(character_id, SYNERGY["archer"])
	return str(table.get(key, key.to_upper()))


static func localize_upgrade(upgrade: Dictionary, character_id: String = "") -> Dictionary:
	if character_id.is_empty():
		character_id = char_id()
	var out := upgrade.duplicate(true)
	var by_id: Dictionary = UPGRADE_NAMES.get(str(upgrade.get("id", "")), {})
	var override: Dictionary = by_id.get(character_id, {})
	if not override.is_empty():
		if override.has("title"):
			out["title"] = override["title"]
		if override.has("desc"):
			out["desc"] = override["desc"]
	return out


static func localize_duke_title(deal_id: String, fallback: String, character_id: String = "") -> String:
	if character_id.is_empty():
		character_id = char_id()
	var by_id: Dictionary = DUKE_NAMES.get(deal_id, {})
	var override: Dictionary = by_id.get(character_id, {})
	if override.has("title"):
		return str(override["title"])
	return fallback
