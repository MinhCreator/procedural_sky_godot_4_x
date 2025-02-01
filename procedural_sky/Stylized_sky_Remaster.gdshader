shader_type sky;
render_mode use_half_res_pass;

#include "dependencies/shoot_stars/shooting_stars.gdshaderinc"
#include "dependencies/cloud/clouds.gdshaderinc"
#include "dependencies/stars/star.gdshaderinc"
#include "dependencies/sun_stuff.gdshaderinc"
#include "dependencies/moon_stuff.gdshaderinc"

// Sky Gradients
group_uniforms sky_color;
uniform vec3 day_bottom_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 day_top_color : source_color = vec3(1.0, 1.0, 1.0);
uniform float blend_sunset = 1.0;
uniform vec3 sunset_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 sunset_top_color : source_color = vec3(0.0, 0.0, 0.0);

uniform vec3 night_bottom_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 night_top_color : source_color = vec3(0.0, 0.0, 0.0);
uniform vec3 light_scatter : source_color = vec3(1.0);

// Horizon Stuff
//group_uniforms horizon;
//uniform vec3 horizon_color_day : source_color = vec3(1.0, 1.0, 1.0);
//uniform vec3 horizon_color_sunset : source_color = vec3(1.0, 1.0, 1.0);
//uniform vec3 horizon_color_night : source_color = vec3(0.0, 0.8, 1.0);
//uniform float horizon_falloff: hint_range(0.0, 1.0, 0.1);

void sky() {
	//vec3 light_lerps = clamp(light_scatter, 0.2, 1.0) * vec3(0.01);

	float horizon_mask = abs(EYEDIR.y);
	float bottom_mask = smoothstep(0.5, 0.45, SKY_COORDS.y);
	//vec2 sky_uv = EYEDIR.xz / EYEDIR.y;

	float day_amount = clamp(LIGHT0_DIRECTION.y, 0.0, 1.0);
	float night_amount = clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);

	vec3 gradient_day = mix(day_bottom_color, day_top_color, clamp(EYEDIR.y, 0.1, 1.0)) * day_amount ;

	float sunset_amount = clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0);

	vec3 gradient_sunset = blend_sunset * mix(clamp(sunset_bottom_color,0.2, 1.0), sunset_top_color, clamp(EYEDIR.y, 0.0, 0.5)) * sunset_amount;
	//vec3 gradient_sunset = light_scatter * (1.0 - horizon_mask) * mix(sunset_bottom_color, sunset_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * sunset_amount;
	vec3 bottom_color = day_bottom_color * sunset_bottom_color * night_bottom_color;
	//vec3 gradient_sunset = light_scatter * (1.0 - horizon_mask) * sunset_amount;
	//vec3 gradient_sunset = light_scatter * (1.0 - horizon_mask);

	//float night_amount = clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);

	vec3 gradient_night = mix(night_bottom_color, night_top_color, clamp(EYEDIR.y, 0.0, 1.0)) * night_amount;


	vec3 sky_gradients = gradient_day + gradient_sunset + gradient_night;

	float sun_distance = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	float sun_power = 1.0 - clamp(sun_distance / sun_size, 0.0, 1.0);

	//float sun_disc = clamp(sun_power / sun_blur, sun_power + sun_intensity, 1.0);

	float sun_disc = clamp(sun_power / sun_blur, sun_power, 1.0);
	vec3 sun = sun_col * sun_disc;

	// moon phase

	//float moon_distance = distance(EYEDIR.xyz, -LIGHT0_DIRECTION);
	float moon_distance = distance(EYEDIR.xyz, -LIGHT0_DIRECTION);
	float moon_power = 1.0 - clamp(moon_distance / moon_size, 0.0, 1.0);
	float moon_disc = clamp(moon_power / 0.01, moon_power, 1.0);

	//float moon_crescent_distance = distance(vec3(EYEDIR.x + moon_crescent_offset, EYEDIR.yz), -LIGHT0_DIRECTION);

	float moon_crescent_distance = distance(vec3(EYEDIR.x + moon_crescent_offset, EYEDIR.yz), -LIGHT0_DIRECTION);
	float moon_crescent_power = 1.0 - clamp(moon_crescent_distance / moon_size, 0.0, 1.0) ;
	float moon_crescent_disc = clamp(moon_crescent_power / 0.01, moon_crescent_power, 1.0);

	vec3 moon_crescent = moon_col * moon_crescent_disc;
	vec3 moon = clamp((moon_col * moon_disc) - moon_crescent, 0.0 , 1.0);


	//float horizon = 1.0 - abs(EYEDIR.y + horizon_falloff);

	//vec3 horizon_glow_amount_day = clamp(horizon * clamp(LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_day;

	//vec3 horizon_glow_amount_sunset = clamp(horizon * clamp(1.0 - abs(LIGHT0_DIRECTION.y), 0.0, 1.0), 0.0, 1.0) * horizon_color_sunset;

	//vec3 horizon_glow_night = clamp(horizon * clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0), 0.0, 1.0) * horizon_color_night;

	//vec3 horizon_glow = horizon_glow_amount_day + horizon_glow_amount_sunset + horizon_glow_night;



	if(stars_intensity > 0.0)
	{
		vec2 stars = voronoi(EYEDIR * 25.0).xz;
		sky_gradients += smoothstep(0.025 + ((1.0 + sin(TIME + stars.y)) / 2.0) * 0.05, 0.0, stars.x) * stars_intensity;
	}

	if(shooting_stars_intensity > 0.0)
	{
		sky_gradients += get_shooting_star(EYEDIR) * shooting_stars_intensity * shooting_star_tint;
	}

	if(high_clouds_density > 0.0)
	{
		vec2 high_clouds_uv = (EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0)) * 0.25 + TIME * 0.001;
		float high_clouds_mask = texture(high_clouds_sampler, high_clouds_uv).x;
		sky_gradients = mix(sky_gradients, clouds_light_color, smoothstep(0.0, 1.0, high_clouds_mask) * horizon_mask * bottom_mask * high_clouds_density);
	}


	vec3 sun_moon = sun + moon;
	sun_moon = clamp(sun_moon, 0.0, 1.0);

	sky_gradients = clamp(sky_gradients , 0.0, 1.0);
	//float sun_intensitys = sun_intensity;
	//if (AT_CUBEMAP_PASS) sun_intensitys;

	//vec3 sky = horizon_glow + sky_gradients + sun_moon;
	//AT_HALF_RES_PASS
	if (AT_HALF_RES_PASS)
	{
		vec3 clouds_direction = vec3(EYEDIR.xz / clamp(EYEDIR.y, 0.0, 1.0), 1.0);
		vec2 clouds = EYEDIR.y > 0.0 ? cloud_ray_march(clouds_direction, LIGHT0_DIRECTION) : vec2(0.0);

		//COLOR = mix(sky_gradients, clouds_light_color, exp(-clouds.y * clouds_shadow_intensity));
		COLOR = mix(bottom_color, clouds_light_color, exp(-clouds.y * clouds_shadow_intensity));
		ALPHA = (1.0 - exp(switch_cloud(clouds) * horizon_mask * bottom_mask * 10.0));

	}
	else
	{
		//COLOR.rgb = mix(horizon_glow + sky_gradients + sun_moon, HALF_RES_COLOR.rgb, HALF_RES_COLOR.a);
		COLOR.rgb = mix(sky_gradients + sun_moon, HALF_RES_COLOR.rgb, HALF_RES_COLOR.a);
	}
}