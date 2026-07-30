extends CanvasLayer

@onready var hp_label: Label = $Margin/VBox/HP
@onready var time_label: Label = $Margin/VBox/Time
@onready var lvl_label: Label = $Margin/VBox/LVL
@onready var score_label: Label = $Margin/VBox/Score
@onready var wave_label: Label = $Margin/VBox/Wave
@onready var abilities_label: Label = $Margin/VBox/Abilities
@onready var relic_label: Label = $Margin/VBox/Relic
@onready var buff_label: Label = $Margin/VBox/Buff
@onready var mode_label: Label = $Margin/VBox/Mode
@onready var coins_label: Label = $Margin/VBox/Coins


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func update_hud(hp: int, max_hp: int, lvl: int, abilities: Dictionary = {}, xp: Dictionary = {}) -> void:
	hp_label.text = "HP  %d/%d" % [hp, max_hp]
	time_label.text = "TEMPO  %s" % Global.format_time(Global.survival_time)
	var xp_cur: int = int(xp.get("current", 0))
	var xp_next: int = int(xp.get("next", 1))
	lvl_label.text = "LVL  %d   XP  %d/%d" % [lvl, xp_cur, xp_next]
	score_label.text = "SCORE  %d" % Global.score
	coins_label.text = "MOEDAS  %d" % Global.coins
	wave_label.text = "DIFICULDADE  %d" % Global.wave
	relic_label.text = "RELÍQUIA  %s" % Global.relic_title()

	var mode_auto: bool = bool(abilities.get("auto_mode", true))
	if mode_auto:
		mode_label.text = "MODO AUTO  (TAB = manual)"
		mode_label.modulate = Color(0.55, 1.0, 0.7)
	else:
		mode_label.text = "MODO MANUAL  (TAB = auto)"
		mode_label.modulate = Color(1.0, 0.85, 0.5)

	var dash_txt := _cd_text(abilities.get("dash", 0.0), abilities.get("dash_max", 1.0))
	var rain_cd: float = abilities.get("rain", -1.0)
	var bomb_cd: float = abilities.get("bomb", -1.0)
	var rain_txt := "Q bloqueado" if rain_cd < 0.0 else "Q %s" % _cd_text(rain_cd, abilities.get("rain_max", 1.0))
	var bomb_txt := "E bloqueado" if bomb_cd < 0.0 else "E %s" % _cd_text(bomb_cd, abilities.get("bomb_max", 1.0))
	var synergy: String = str(abilities.get("synergy", ""))
	var syn_txt := ("  |  " + synergy) if not synergy.is_empty() else ""
	abilities_label.text = "DASH %s  |  %s  |  %s%s" % [dash_txt, rain_txt, bomb_txt, syn_txt]

	var buff_t: float = float(abilities.get("boss_buff", 0.0))
	if buff_t > 0.0:
		buff_label.visible = true
		buff_label.text = "FÚRIA DO BOSS  %.1fs  (+dano +spd +tiro +ima)" % buff_t
	else:
		buff_label.visible = false


func _cd_text(left: float, max_cd: float) -> String:
	if left <= 0.0:
		return "PRONTO"
	return "%.1fs" % left
