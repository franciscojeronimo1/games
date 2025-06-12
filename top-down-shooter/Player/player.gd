extends CharacterBody2D
class_name Player

@onready var player: Player = $"."

var bonus_effect_scene = preload("res://Player/lvl_up.tscn")
@export var bullet_sceme : PackedScene
var can_shoot: bool = true
@export var shoot_coldown : float = 2.0
@onready var label: Label = $Label
var upgrades = {
	1: {"shoot_coldown": 0.8},
	10: {"shoot_coldown": 0.5, "move_speed": 500.0},
	15: {"shoot_coldown": 0.3},
	20: {"shoot_coldown": 0.1, "move_speed": 700.0},
	30: {"move_speed": 900.0}
}

@export var hp : int = 10
@export var lvl: int = 1



var move_speed := 300.0
var move_direction := Vector2.ZERO

func _ready() -> void:
	Global.player = self

func _physics_process(delta: float) -> void:
	bonusUP()
	move_direction = Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = move_direction * move_speed
	
	
	var mouse_dir = get_global_mouse_position() - global_position
	var mouse_dir_contrario = get_global_mouse_position() + global_position
	
	if Input.is_action_just_pressed('shoot') and can_shoot:
		_shoot(mouse_dir)
		if lvl >= 15:
			_shoot(mouse_dir_contrario)
	
	move_and_slide()
func _shoot(direction):
	can_shoot = false
	
	var bullet_instance = bullet_sceme.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.set_direction(direction)
	
	await get_tree().create_timer(shoot_coldown).timeout
	can_shoot = true

func bonusUP():
	if upgrades.has(lvl):  # Verifica se o nível atual tem upgrades
		for key in upgrades[lvl]:  # Para cada atributo no upgrade
			self.set(key, upgrades[lvl][key])  # Atualiza o atributo dinamicamente


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group('enemies'):
		hp -=1
		print('perdeu ' + str(hp))
	if hp <= 0:
		game_over()
		
		
func game_over():
	get_tree().reload_current_scene()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group('xpdropInicial'):
		lvl += 1
		
		label.text = 'LVL: '+ str(lvl)
		print(lvl)
