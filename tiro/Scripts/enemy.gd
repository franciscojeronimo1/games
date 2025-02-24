extends CharacterBody3D

@export
var move_speed : float

@onready var navigation_agent := $NavigationAgent3D as NavigationAgent3D

var player : Node3D
@export
var initial_health : float

var current_health : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_health = initial_health
	$Control/TextureProgressBar.max_value = initial_health

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_health <= 0:
		queue_free()
	if player == null:
		player = get_tree().get_first_node_in_group("Player")
		
	if player != null:
		navigation_agent.set_target_position(player.global_position)
		
		velocity = global_position.direction_to(navigation_agent.get_next_path_position()) * move_speed
		
		move_and_slide()
		


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Bullet"):
		current_health -= 10
		$Control/TextureProgressBar.value = current_health
