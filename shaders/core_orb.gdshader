shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 body_col : source_color = vec4(0.22, 0.92, 1.0, 1.0);
uniform float body_ratio = 0.94;
uniform float aa_width = 0.01;
uniform float flash = 0.0;

void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float d = length(p);
	float edge = max(body_ratio, 0.05);
	float aa = max(aa_width, 0.002);
	float body = 1.0 - smoothstep(edge - aa, edge + aa, d);
	float z = sqrt(max(edge * edge - d * d, 0.0));
	vec3 n = vec3(p.x, p.y, z);
	float nlen = length(n);
	n = nlen > 0.001 ? n / nlen : vec3(0.0, 0.0, 1.0);
	float ndl = clamp(dot(n, normalize(vec3(-0.18, -0.50, 0.86))), 0.0, 1.0);
	float shade = 0.82 + ndl * 0.28 + flash * 0.08;
	COLOR = vec4(body_col.rgb * shade, body);
}
