extends CanvasLayer

@onready var hp_label: Label = $Margin/VBox/HP
@onready var time_label: Label = $Margin/VBox/Time
@onready var lvl_label: Label = $Margin/VBox/LVL
@onready var score_label: Label = $Margin/VBox/Score
@onready var wave_label: Label = $Margin/VBox/Wave


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func update_hud(hp: int, max_hp: int, lvl: int) -> void:
	hp_label.text = "HP  %d/%d" % [hp, max_hp]
	time_label.text = "TEMPO  %s" % Global.format_time(Global.survival_time)
	lvl_label.text = "LVL  %d" % lvl
	score_label.text = "SCORE  %d" % Global.score
	wave_label.text = "WAVE  %d" % Global.wave
