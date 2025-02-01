#ifndef MOON
#define MOON

// Moon Stuff
group_uniforms moon;
uniform vec3 moon_col: source_color = vec3(1.0);
uniform sampler2D moon_texture : repeat_disable, filter_linear_mipmap;
uniform int moon_custom_texture: hint_range(0, 1);
uniform float moon_size: hint_range(0.01, 1.0) = 1.0;
uniform float moon_crescent_offset: hint_range(-1.0, 0.0);

vec3 switch_moon (vec3 moon_color, vec3 moon_tex){
	switch(moon_custom_texture) {
		case 0:
			return moon_color;

		case 1:
			return moon_tex;
	}
}

#endif