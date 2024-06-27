shader_type canvas_item;

uniform bool is_active = false;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	if (is_active == true){
		vec4 previous_color = texture(TEXTURE, UV);
		COLOR = vec4 (1.0, 0.0, 0.0,previous_color.a);
	}
	
	
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
