extends Sprite2D
## Chão infinito: um Sprite2D que acompanha a câmera e repete a textura no mundo.

@export var floor_scale: float = 0.5
@export var margin_tiles: float = 2.0


func _ready() -> void:
	z_index = -100
	centered = true
	region_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	scale = Vector2.ONE * floor_scale
	_update_floor()


func _process(_delta: float) -> void:
	_update_floor()


func _update_floor() -> void:
	if texture == null:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return

	var tex_size := texture.get_size()
	var view_size := get_viewport_rect().size / cam.zoom
	# Região em pixels da textura: cobre a tela + margem pra não aparecer borda
	var cover := (view_size / floor_scale) + tex_size * margin_tiles
	region_rect.size = cover

	var center := cam.get_screen_center_position()
	global_position = center
	# Offset de UV trava o padrão no mundo (não "anda" com a câmera)
	region_rect.position = Vector2(
		fposmod(center.x / floor_scale - cover.x * 0.5, tex_size.x),
		fposmod(center.y / floor_scale - cover.y * 0.5, tex_size.y)
	)
