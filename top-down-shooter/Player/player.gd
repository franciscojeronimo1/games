extends CharacterBody2D
class_name Player

@export var bullet_sceme : PackedScene
var can_shoot: bool = true
@export var shoot_coldown : float = 2.0
@onready var label: Label = $Label
@onready var buffs: Control = $buffs

@export var hp : int = 10
var lvl: int = 1



var move_speed := 300.0
var move_direction := Vector2.ZERO

func _ready() -> void:
	Global.player = self

func _physics_process(delta: float) -> void:
	bonusUP()
	move_direction = Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = move_direction * move_speed
	
	
	var mouse_dir = get_global_mouse_position() - global_position
	
	if Input.is_action_just_pressed('shoot') and can_shoot:
		_shoot(mouse_dir)
	
	move_and_slide()
func _shoot(direction):
	can_shoot = false
	
	var bullet_instance = bullet_sceme.instantiate()
	get_tree().current_scene.add_child(bullet_instance)
	bullet_instance.global_position = global_position
	bullet_instance.set_direction(direction)
	
	await get_tree().create_timer(shoot_coldown).timeout
	can_shoot = true


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

func bonusUP():
	if lvl == 2:
		get_tree().paused = true
		buffs.visible = true

		


func _on_button_pressed() -> void:
	lvl +=1
	buffs.visible = false
	get_tree().paused = false
	


func _on_button_2_pressed() -> void:
	lvl +=1
	buffs.visible = false
	get_tree().paused = false


func _on_button_3_pressed() -> void:
	lvl +=1
	buffs.visible = false
	get_tree().paused = false
