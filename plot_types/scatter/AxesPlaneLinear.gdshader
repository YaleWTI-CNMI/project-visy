shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform float line_width = 0.05;
uniform float line_falloff = 0.7;
uniform float x_step = 0.1;
uniform float y_step = 0.1;
uniform float z_step = 0.1;
uniform vec3 axes;


void vertex() {
	// Called for every vertex the material is visible on.
}

float map_value(float target_min, float target_max, float original_min, float original_max, float input_value) {
	return target_min + (input_value - original_min) * (target_max - target_min) / (original_max - original_min);
}

float get_closeness(float stp, float value) {
	return abs(stp / 2.0 - (value - floor(value / stp) * stp)) * 2.0 / stp;
}

void fragment() {
	vec4 coords = inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	float x = coords.x + 0.5;
	float y = coords.y + 0.5;
	float z = coords.z + 0.5;

	ALBEDO = abs(vec3(x * axes.r, y * axes.g, z * axes.b));

	float closeness_x = get_closeness(x_step, x) * axes.x;
	float closeness_y = get_closeness(y_step, y) * axes.y;
	float closeness_z = get_closeness(z_step, z) * axes.z;

	float alpha = max(max(pow(closeness_x, 20), pow(closeness_y, 20)), pow(closeness_z, 20));
	if(alpha >= 1.0 - line_width)
		alpha = 1.0;
	else if(alpha < 1.0 - line_width - line_falloff)
		alpha = 0.1;

	if(FRONT_FACING)
		ALPHA = alpha;
	else
		ALPHA = 0.05;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
