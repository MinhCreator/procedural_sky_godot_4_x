shader_type sky;
render_mode use_half_res_pass;


// Sky Gradients
group_uniforms sky_color;
uniform vec3 day_bottom_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 day_top_color : source_color = vec3(1.0, 1.0, 1.0);

uniform vec3 sunset_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 sunset_top_color : source_color = vec3(0.0, 0.0, 0.0);

uniform vec3 night_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 night_top_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 light_scatter : source_color = vec3(1.0);

// Horizon Stuff
group_uniforms horizon;
uniform vec3 horizon_color_day : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 horizon_color_sunset : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 horizon_color_night : source_color = vec3(0.0, 0.8, 1.0);
uniform float horizon_falloff: hint_range(0.0, 1.0, 0.1);


// Sun Stuff
group_uniforms sun;
uniform vec3 sun_col: source_color = vec3(1.0);
uniform float sun_size: hint_range(0.01, 1.0) = 1.0;
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01;
uniform float sun_intensity:hint_range(0.0, 3.0, 0.01);
// Moon Stuff
group_uniforms moon;
uniform vec3 moon_col: source_color = vec3(1.0);
uniform float moon_size: hint_range(0.01, 1.0) = 1.0;
uniform float moon_crescent_offset: hint_range(-1.0, 1.0) = 0.5;
uniform float moon_intensity:hint_range(0.0, 3.0, 0.01);



group_uniforms clouds;
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

group_uniforms stars;
uniform float stars_intensity : hint_range(0.0, 5.0, 0.1) = 0.0;

group_uniforms shooting_stars;
uniform float shooting_stars_intensity : hint_range(0.0, 10.0, 0.1) = 0.0;
uniform sampler2D shooting_star_sampler : filter_linear, repeat_disable;
uniform vec3 shooting_star_tint : source_color;


float rand(float n){return fract(sin(n) * 43758.5453123);}

vec3 hash( vec3 x ){
	x = vec3( dot(x,vec3(127.1,311.7, 74.7)),
			  dot(x,vec3(269.5,183.3,246.1)),
			  dot(x,vec3(113.5,271.9,124.6)));
	return fract(sin(x)*43758.5453123);
}

vec3 voronoi( in vec3 x ){
	vec3 p = floor( x );
	vec3 f = fract( x );
	
	float id = 0.0;
	vec2 res = vec2( 100.0 );
	for( int k=-1; k<=1; k++ )
	for( int j=-1; j<=1; j++ )
	for( int i=-1; i<=1; i++ ) {
		vec3 b = vec3( float(i), float(j), float(k) );
		vec3 r = vec3( b ) - f + hash( p + b );
		float d = dot( r, r );
		if( d < res.x ) {
			id = dot( p+b, vec3(1.0,57.0,113.0 ) );
			res = vec2( d, res.x );
		} else if( d < res.y ) {
			res.y = d;
		}
    }
    return vec3( sqrt( res ), abs(id) );
}

mat3 direction_to_matrix(vec3 direction) {
	vec3 x_axis = normalize(cross(vec3(0.0, 1.0, 0.0), direction));
	vec3 y_axis = normalize(cross(direction, x_axis));
	return mat3(vec3(x_axis.x, y_axis.x, direction.x),
				vec3(x_axis.y, y_axis.y, direction.y),
				vec3(x_axis.z, y_axis.z, direction.z));
}

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

vec3 random_direction(float seed){
	float phi = rand(seed) * PI;
	float costheta = rand(seed + 100.0) * 2.0 - 1.0;
	float theta = acos(costheta);
	return vec3( sin(theta) * cos(phi), (theta) * sin(phi), cos(theta) );
}

float get_shooting_star(vec3 eyedir){
	float shooting_star = 0.0;
	for(int i = 0; i < 4; i++){
		float base_rand = rand(float(i));
		float time = TIME + base_rand * 2.0;
		float duration = 0.5 + base_rand;
		float seed = floor(time / duration) * duration + base_rand;
		float progress = mod(time, duration) / duration;
		float rand_value = rand(seed + 100.0);
		float rand_scale = base_rand * 10.0;
		float a = rand_value * 0.8;
		mat3 angle = mat3(vec3(cos(a), -sin(a), 0.0), vec3(sin(a), cos(a), 0.0), vec3(0.0, 0.0, 1.0));
		vec3 shooting_dir = direction_to_matrix(random_direction(seed)) * angle * eyedir;
		vec2 shooting_uv = ((shooting_dir.xy + vec2(0.0, progress * 0.4)) * (8.0 + rand_scale)) + vec2(0.5);

		float shooting_mask = ceil(
			clamp(shooting_uv.x * (1.0 - shooting_uv.x), 0.0, 1.0) *
			clamp(shooting_uv.y * (1.0 - shooting_uv.y), 0.0, 1.0)
			) * ceil(shooting_dir.z);
			
		shooting_star = clamp(
			shooting_star + texture(shooting_star_sampler, shooting_uv).x
			* sin(progress * PI)
			* shooting_mask * rand_value,
		0.0, 1.0);
	}
	return clamp(shooting_star, 0.0, 1.0);
}



void sky() {
	
	float horizon_mask = abs(EYEDIR.y);
	float bottom_mask = smoothstep(0.5, 0.45, SKY_COORDS.y);
	
	vec2 sky_uv = EYEDIR.xz / EYEDIR.y;
	
	
	float day_amount = clamp(LIGHT0_DIRECTION.y, 0.0, 1.0);
	
	vec3 gradient_day = mix(day_bottom_color, day_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * day_amount;
	
	float sunset_amount = clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0);
	
	//vec3 gradient_sunset = mix(sunset_bottom_color, sunset_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * sunset_amount;
	vec3 gradient_sunset = light_scatter * (1.0 - horizon_mask) * mix(sunset_bottom_color, sunset_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * sunset_amount;	
	
	float night_amount = clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);
	
	vec3 gradient_night = mix(night_bottom_color, night_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * night_amount;
	
	
	vec3 sky_gradients = gradient_day + gradient_sunset + gradient_night;
	
	
	float horizon = 1.0 - abs(EYEDIR.y + horizon_falloff);
	
	vec3 horizon_glow_amount_day = clamp(horizon * clamp(LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_day;
	
	vec3 horizon_glow_amount_sunset = clamp(horizon * clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0), 0.0, 1.0) * horizon_color_sunset;
	
	vec3 horizon_glow_night = clamp(horizon * clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_night;
	
	vec3 horizon_glow = horizon_glow_amount_day + horizon_glow_amount_sunset + horizon_glow_night;
	
	
	float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);
	float sun_disc = clamp(sun_power / sun_blur, sun_power + sun_intensity, 1.0);
	vec3 sun = sun_col * sun_disc;
	
	
	
	float moon_distance = distance(EYEDIR.xyz, -LIGHT0_DIRECTION);
	float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
	float moon_disc = clamp(moon_power / 0.01, moon_power + moon_intensity, 1.0);
	
	// moon phase
	
	float moon_crescent_distance = distance(vec3(EYEDIR.x + moon_crescent_offset, EYEDIR.yz), -LIGHT0_DIRECTION);
	
	float moon_crescent_power = 1.0 - clamp(moon_crescent_distance / moon_size, 0.0, 1.0) ;
	
	float moon_crescent_disc = clamp(moon_crescent_power / 0.01, moon_crescent_power, 1.0);
	
	vec3 moon_crescent = moon_col * moon_crescent_disc;
	
	vec3 moon = clamp( (moon_col * moon_disc) - moon_crescent, 0.0 , 1.0);
	
	
	if(stars_intensity > 0.0){
		vec2 stars = voronoi(EYEDIR * 25.0).xz;
		sky_gradients += smoothstep(0.025 + ((1.0 + sin(TIME + stars.y)) / 2.0) * 0.05, 0.0, stars.x) * stars_intensity;
	}
	
	if(shooting_stars_intensity > 0.0){
		sky_gradients += get_shooting_star(EYEDIR) * shooting_stars_intensity * shooting_star_tint;
	}
	
	if(high_clouds_density > 0.0){
		vec2 high_clouds_uv = (EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0)) * 0.25 + TIME * 0.001;
		float high_clouds_mask = texture(high_clouds_sampler, high_clouds_uv).x;
		sky_gradients = mix(sky_gradients, clouds_light_color, smoothstep(0.0, 1.0, high_clouds_mask) * horizon_mask * bottom_mask * high_clouds_density);
	}


	vec3 sun_moon = sun + moon;
	sun_moon = clamp(sun_moon, 0.0, 1.0);
	
	sky_gradients = clamp(sky_gradients , 0.0, 1.0);
	
	
	
	vec3 sky = horizon_glow + sky_gradients + sun_moon;
	
	if (AT_HALF_RES_PASS) {
		vec3 clouds_direction = vec3(EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0), 1.0);
		vec2 clouds = EYEDIR.y > 0.0 ? cloud_ray_march(clouds_direction, LIGHT0_DIRECTION) : vec2(0.0);
		
		COLOR = mix(sky_gradients, clouds_light_color, exp(-clouds.y * clouds_shadow_intensity));
		ALPHA = (1.0 - exp(-clouds.x * horizon_mask * bottom_mask * 10.0));
		
	}else{
		COLOR.rgb = mix(sky, HALF_RES_COLOR.rgb, HALF_RES_COLOR.a);
	}
}