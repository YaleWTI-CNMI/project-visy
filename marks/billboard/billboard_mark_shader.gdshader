shader_type spatial;

render_mode unshaded;

uniform float global_size = 1;
uniform sampler2D mark_texture : filter_nearest;

void vertex() {
	VERTEX *= global_size;
	VERTEX *= INSTANCE_CUSTOM.r;

	 // Get the model position in world space
    vec3 model_pos = MODEL_MATRIX[3].xyz;

    // For VR, we'll use the eye position directly
    vec3 camera_pos = CAMERA_POSITION_WORLD;
    vec3 to_camera = normalize(camera_pos - model_pos);

    // Calculate the right vector
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), to_camera));
    // Keep up vector strictly vertical
    vec3 up = vec3(0.0, 1.0, 0.0);
    // Recalculate forward vector to ensure orthogonality
    vec3 forward = normalize(cross(right, up));

    // Build the billboard matrix
    mat4 billboard_matrix = mat4(
        vec4(right, 0.0),
        vec4(up, 0.0),
        vec4(forward, 0.0),
        vec4(model_pos, 1.0)
    );

    MODELVIEW_MATRIX = VIEW_MATRIX * billboard_matrix;
}

void fragment() {
	vec4 tex_mask = texture(mark_texture, UV);
	ALBEDO = tex_mask.rgb * COLOR.rgb;
	ALPHA = tex_mask.a;
	ALPHA_SCISSOR_THRESHOLD = 0.01;
}