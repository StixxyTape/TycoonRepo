shader_type spatial;

render_mode depth_prepass_alpha, cull_disabled;
uniform vec3 newColor = vec3(1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = newColor;
	ALPHA = 0.5f;
}
