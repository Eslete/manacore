shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 body_col : source_color = vec4(0.22, 0.92, 1.0, 1.0);
uniform float body_ratio = 0.70;
uniform float glow_amt = 0.48;
uniform float aa_width = 0.01;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p);
	float edge = max(body_ratio, 0.05);
	float aa = max(aa_width, 0.002);
	float body = 1.0 - smoothstep(edge - aa, edge + aa, d);
	float t = max(d - edge, 0.0) / max(1.0 - edge, 0.001);
	float pulse = 0.05 * (0.5 + 0.5 * sin(TIME * 1.65));
	float glow = pow(1.0 - clamp(t, 0.0, 1.0), 2.9) * (glow_amt + pulse);
	glow *= 1.0 - body;
	COLOR = vec4(body_col.rgb * glow, glow);
}
