shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler3D volume_data;
uniform float steps = 64.0;
uniform float contrast = 1.0;

uniform sampler2D filter_tex;
uniform sampler2D color_map;

uniform vec3 low_clamp = vec3(0.0);
uniform vec3 high_clamp = vec3(1.0);

varying vec3 world_pos;

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	//vec3 eye_world = CAMERA_POSITION_WORLD + EYE_OFFSET;
    //vec3 ray_dir_world = normalize(world_pos - eye_world);

    mat4 inv_model = inverse(MODEL_MATRIX);
    //vec3 ray_origin = (inv_model * vec4(eye_world, 1.0)).xyz;
    //vec3 ray_dir = normalize((inv_model * vec4(ray_dir_world, 0.0)).xyz);

	// Transform both eye and frag positions into object space
	vec3 eye_world = CAMERA_POSITION_WORLD;
	vec3 eye_obj = (inverse(MODEL_MATRIX) * vec4(eye_world, 1.0)).xyz;

	vec3 frag_obj = (inverse(MODEL_MATRIX) * vec4(world_pos, 1.0)).xyz;
	vec3 ray_dir = normalize(frag_obj - eye_obj);
	vec3 ray_origin = eye_obj;


    vec3 box_min = vec3(-0.5);
    vec3 box_max = vec3(0.5);

    vec3 tmin = (box_min - ray_origin) / ray_dir;
    vec3 tmax = (box_max - ray_origin) / ray_dir;
    vec3 t1 = min(tmin, tmax);
    vec3 t2 = max(tmin, tmax);
    float t_near = max(max(t1.x, t1.y), t1.z);
    float t_far = min(min(t2.x, t2.y), t2.z);

    if (t_near > t_far || t_far < 0.0) {
        discard;
    }

    float dt = (t_far - max(t_near, 0.0)) / steps;

	// Stable noise-based jitter per pixel
	float offset = fract(sin(dot(FRAGCOORD.xy * 100.0 ,vec2(12.9898,78.233))) * 43758.5453);

	// Randomized initial t
	float t = max(t_near, 0.0) + dt * offset;


    vec3 accum_color = vec3(0.0);
    float alpha_budget = 1.0;
	int i = 1;
	int dead_i = 0;
	float steps_dynamic = mix(steps, steps * 2.0, length(ray_dir));


    for (; i <= int(steps); i++) {
	    vec3 p = ray_origin + ray_dir * t;
		vec3 uvw = clamp((p - box_min) / (box_max - box_min), 0.0, 1.0);
	    vec4 sample = texture(volume_data, uvw);

		if(!(all(greaterThanEqual(uvw, low_clamp)) && all(lessThanEqual(uvw, high_clamp)))) {
			t += dt;
			dead_i++;
			continue;
		}

		//sample.a *= pow(length(sample.rgb) / length(vec3(1)), contrast);

		vec4 filter_sample = texture(filter_tex, vec2(clamp(sample.r, 0.0, 1.0), 0.5));
		sample.a *= filter_sample.r;


	    if (sample.a < 0.01) {
	        t += dt;
			dead_i++;
	        continue;
	    }

		vec4 color_sample = texture(color_map, vec2(sample.r, 0.5));
		sample.rgb = color_sample.rgb;

	    accum_color += sample.rgb * sample.a * (alpha_budget);
	    alpha_budget *= (1.0 - sample.a);

	    if (alpha_budget < 0.01) break;

	    t += dt;
	}



    float final_alpha = 1.0 - alpha_budget;
    ALBEDO = clamp(accum_color, 0.0, 1.0);// / max(1.0, float(i - dead_i + 1));
    ALPHA = final_alpha;

}
