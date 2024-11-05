shader_type spatial;

uniform vec3 albedo : source_color;
uniform sampler2D noise;
uniform float noise_scale = 10.0;
uniform float height_scale;

varying float height;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	height = texture(noise, world_pos.xz / noise_scale).r;
	VERTEX.y += height * height_scale;
}

void fragment() {
	ALBEDO = albedo;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
