extends CharacterBody2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var character: AnimatedSprite2D = $Character



func _physics_process(delta: float) -> void:
	velocity = Input.get_vector("ui_left","ui_right","ui_up","ui_down") * 100
	move_and_slide()
	power()
	if velocity:
		character.play("run")
	else:
		character.play("idle")

func power():
	if Input.is_action_just_pressed("clik_left"):
		animation_player.play("fogo")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name =="fogo":
		animation_player.play("RESET")
