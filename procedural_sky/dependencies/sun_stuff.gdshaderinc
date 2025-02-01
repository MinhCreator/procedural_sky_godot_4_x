#ifndef SUN
#define SUN

// Sun Stuff
group_uniforms sun;
uniform vec3 sun_col: source_color = vec3(1.0);
uniform float sun_size: hint_range(0.01, 1.0) = 1.0;
uniform float sun_blur: hint_range(0.01, 1.0) = 0.01;
uniform float sun_intensity:hint_range(0.0, 3.0, 0.01);





#endif