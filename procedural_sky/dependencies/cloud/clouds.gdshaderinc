#ifndef STYLIZED_CLOUDS
#define STYLIZED_CLOUDS

group_uniforms clouds;
uniform int realistic_cloud: hint_range(0,1);
uniform sampler2D cloud_shape_sampler : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cloud_noise_sampler : filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cloud_curves;
uniform int clouds_samples : hint_range(8, 32, 8) = 16;
uniform int shadow_sample : hint_range(1, 4, 1) = 4;
uniform float clouds_density : hint_range(0.0, 1.0, 0.1) = 0.5;
uniform float clouds_scale : hint_range(0.5, 1.5, 0.1) = 1.0;
uniform float clouds_smoothness : hint_range(0.01, 0.1, 0.01) = 0.035;
uniform vec3 clouds_light_color : source_color;
uniform float clouds_shadow_intensity : hint_range(0.1, 10.0, 0.1) = 1.0;

group_uniforms high_clouds;
uniform sampler2D high_clouds_sampler;
uniform float high_clouds_density : hint_range(0.0, 1.0, 0.05) = 0.0;


float cloud_density(vec3 p, float progress){
	float t_o = TIME * 0.001;
	float t_o_small = TIME * -0.005;
	float noise = texture(cloud_noise_sampler, p.xy * 4.0 + t_o_small).x * 0.1 + 0.9;
	float clouds_shape = texture(cloud_shape_sampler, (p.xy + t_o) * clouds_scale).x;
	float height_curve = texture(cloud_curves, vec2(progress, 0.0)).x;
	float base_density = 1.0 - clouds_density;
	float density =
	smoothstep(base_density - clouds_smoothness,
	base_density + clouds_smoothness,
	clouds_shape * noise * height_curve
	);
	return density;
}

vec2 cloud_ray_march(vec3 direction, vec3 sun_direction){

	float density = 0.0;
	float light = 0.0;

	float height = 0.03;
	vec3 sample_point = vec3(0.0, 0.0, 2.0);

	int loop_offset = clouds_samples * 3;

	for(int i = loop_offset; i < clouds_samples + loop_offset; i++) {
		float progress = float(i) / float(clouds_samples);
		sample_point = direction * height * progress;
		float point_density = cloud_density(sample_point, progress);
		density += point_density;

		float point_light = 0.0;
		for(int f = 0; f < shadow_sample; f++){
			float shadow_progress = float(f) / float(shadow_sample);
			vec3 shadow_offset = sun_direction * height * shadow_progress;
			point_light += cloud_density(sample_point + shadow_offset, progress);
		}
		light += point_light;
	}
	return vec2(clamp(density, 0.0, 1.0), light / float(shadow_sample * clouds_samples));
}

float switch_cloud(vec2 clouds) {
	switch (realistic_cloud) { // `i` should be a signed integer expression.
    case 0:
        return -clouds.x;
    case 1:
        return -clouds.y; // `break` or `return` to avoid running the next `case`.

	}
}

#endif