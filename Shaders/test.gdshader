shader_type sky;
render_mode use_quarter_res_pass;

uniform float CloudsCutoffOutside = 0.00999999977648;
uniform float CloudsSmoothnessOutside = 0.01400000043213;
uniform float CloudsScrollSpeed2 = 0.00999999977648;
uniform float CloudsScrollSpeed = -0.01999999955297;
uniform float CloudsScale = -0.27500000596046;
uniform sampler2D Noise1 : source_color, filter_linear_mipmap_anisotropic;
uniform float CloudsScale2 = 0.04500000178814;
uniform sampler2D Distort : source_color, filter_linear_mipmap_anisotropic;
uniform float CloudsDistort = 0.12999999523163;
uniform float CloudsScale3 = 0.10999999940395;
uniform sampler2D Noise2 : source_color, filter_linear_mipmap_anisotropic;
uniform float StarsScale = 1.29299998283386;
uniform sampler2D StarsTex : hint_default_black;
uniform sampler2D tex_sky_70 : source_color;
uniform vec4 NightBottomCol : source_color = vec4(0.226957, 0.206687, 0.418709, 1.000000);
uniform vec4 NightTopCol : source_color = vec4(0.140878, 0.086519, 0.367720, 1.000000);
uniform vec4 DayBottomCol : source_color = vec4(0.000000, 0.663457, 0.664935, 1.000000);
uniform vec4 DayTopCol : source_color = vec4(0.258824, 0.541176, 1.000000, 1.000000);
uniform float MoonRadius = 0.09000000357628;
uniform vec3 MoonOffset = vec3(0.030000, 0.000000, 0.000000);
uniform float MoonIntensity = 8;
uniform float SunRadius = 0.11999999731779;
uniform float SunIntensity = 8;
uniform vec4 HorizonCol : source_color = vec4(1.000000, 0.318287, 0.232534, 1.000000);
uniform vec4 CloudsInsideNight : source_color = vec4(0.339844, 0.230469, 0.566406, 1.000000);
uniform float CloudsInsideIntensity = 5.10200023651123;
uniform float CloudsEdgeIntensity = 5.10200023651123;
uniform vec4 CloudsEdgeNight : source_color = vec4(0.394531, 0.140625, 0.582031, 1.000000);
uniform float CloudsCutoffInside = 0.08500000089407;
uniform float CloudsSmoothnessInside = 0.06499999761581;
uniform vec4 CloudEdgeDay : source_color = vec4(1.000000, 1.000000, 1.000000, 1.000000);
uniform float CloudsInsideIntensity2 = 5.10200023651123;
uniform vec4 CloudInsideDay : source_color = vec4(0.000002, 0.786308, 0.791455, 1.000000);
uniform float CloudsEdgeIntensity2 = 5.10200023651123;



void sky() {
// FloatParameter:144
	float cloud_cutoff_outside = CloudsCutoffOutside;


// FloatParameter:145
	float cloud_smoothness_outside = CloudsSmoothnessOutside;


// FloatOp:146
	float n_out146p0 = cloud_cutoff_outside + cloud_smoothness_outside;


// Input:174
	float time = TIME;


// FloatParameter:159
	float cloud_sroll_speed2 = CloudsScrollSpeed2;


// FloatOp:160
	float cloud_roll_speed2 = time * cloud_sroll_speed2;


// Input:56
	vec3 eyedir = EYEDIR;
	float eyedir_r = eyedir.r;
	float eyedir_g = eyedir.g;
	float eyedir_b = eyedir.b;


// VectorCompose:57
	vec2 eyedir_rb = vec2(eyedir_r, eyedir_b);


// VectorOp:58
	vec2 eyedir_rbg = eyedir_rb / vec2(eyedir_g);


// FloatParameter:76
	float cloud_scroll_speed = CloudsScrollSpeed;


// FloatOp:75
	float cloud_roll_speed = time * cloud_scroll_speed;


// VectorOp:77
	vec2 n_out77p0 = eyedir_rbg - vec2(cloud_roll_speed);


// FloatParameter:79
	float cloud_scale = CloudsScale;


// VectorOp:78
	vec2 n_out78p0 = n_out77p0 * vec2(cloud_scale);


	vec4 noise1;
// Texture2D:73
	noise1 = texture(Noise1, n_out78p0);
	float n_out73p1 = noise1.r;


// VectorOp:80
	vec2 n_out80p0 = eyedir_rbg + vec2(n_out73p1);


// VectorOp:82
	vec2 n_out82p0 = vec2(cloud_roll_speed2) - n_out80p0;


// FloatParameter:86
	float cloud_scale2 = CloudsScale2;


// VectorOp:85
	vec3 n_out85p0 = vec3(n_out82p0, 0.0) * vec3(cloud_scale2);


	vec4 distort;
// Texture2D:81
	distort = texture(Distort, vec2(n_out85p0.xy));
	float distort_r = distort.r;


// FloatParameter:104
	float cloud_distort = CloudsDistort;


// FloatOp:103
	float final_cloud_distort = distort_r * cloud_distort;


// VectorOp:89
	vec2 n_out89p0 = eyedir_rbg + vec2(final_cloud_distort);


// VectorOp:90
	vec2 n_out90p0 = n_out89p0 + vec2(n_out75p0);


// FloatParameter:105
	float n_out105p0 = CloudsScale3;


// VectorOp:107
	vec2 n_out107p0 = n_out90p0 * vec2(n_out105p0);


	vec4 n_out88p0;
// Texture2D:88
	n_out88p0 = texture(Noise2, n_out107p0);
	float n_out88p1 = n_out88p0.r;


// FloatOp:175
	float n_out175p0 = distort_r * n_out88p1;


// FloatFunc:92
	float n_out92p0 = min(max(n_out175p0, 0.0), 1.0);


// Input:94
	vec3 n_out94p0 = EYEDIR;
	float n_out94p2 = n_out94p0.g;


// FloatFunc:95
	float n_out95p0 = min(max(n_out94p2, 0.0), 1.0);


// FloatOp:93
	float n_out93p0 = n_out92p0 * n_out95p0;


// SmoothStep:122
	float n_out122p0 = smoothstep(n_out144p0, n_out146p0, n_out93p0);


// FloatFunc:131
	float n_out131p0 = 1.0 - n_out122p0;


// FloatParameter:154
	float n_out154p0 = StarsScale;


// VectorOp:153
	vec2 n_out153p0 = eyedir_rbg * vec2(n_out154p0);


	vec4 n_out61p0;
// Texture2D:61
	n_out61p0 = texture(StarsTex, n_out153p0);
	float n_out61p1 = n_out61p0.r;


// Input:64
	vec3 n_out64p0 = LIGHT0_DIRECTION;
	float n_out64p2 = n_out64p0.g;
	float n_out64p3 = n_out64p0.b;


// VectorCompose:155
	vec2 n_out155p0 = vec2(n_out64p3, n_out64p2);


// VectorOp:69
	vec2 n_out69p0 = n_out155p0 + eyedir_rbg;


// Texture2D:70
	vec4 n_out70p0 = texture(tex_sky_70, n_out69p0);


// FloatOp:72
	float n_out72p0 = n_out61p1 * n_out70p0.x;


// Step:68
	float n_in68p0 = 0.20000;
	float n_out68p0 = step(n_in68p0, n_out72p0);


// FloatFunc:65
	float n_out65p0 = min(max(n_out64p2, 0.0), 1.0);


// FloatFunc:66
	float n_out66p0 = 1.0 - n_out65p0;


// VectorOp:63
	vec3 n_out63p0 = vec3(n_out68p0) * vec3(n_out66p0);


// FloatOp:152
	float n_out152p0 = n_out131p0 * n_out63p0.x;


// ColorParameter:38
	vec4 n_out38p0 = NightBottomCol;


// ColorParameter:39
	vec4 n_out39p0 = NightTopCol;


// Input:31
	vec3 n_out31p0 = EYEDIR;
	float n_out31p2 = n_out31p0.g;


// Mix:37
	vec3 n_out37p0 = mix(vec3(n_out38p0.xyz), vec3(n_out39p0.xyz), vec3(n_out31p2));


// VectorFunc:52
	vec3 n_out52p0 = max(min(n_out37p0, vec3(1.0)), vec3(0.0));


// ColorParameter:33
	vec4 n_out33p0 = DayBottomCol;


// ColorParameter:34
	vec4 n_out34p0 = DayTopCol;


// Mix:32
	vec3 n_out32p0 = mix(vec3(n_out33p0.xyz), vec3(n_out34p0.xyz), vec3(n_out31p2));


// VectorFunc:51
	vec3 n_out51p0 = max(min(n_out32p0, vec3(1.0)), vec3(0.0));


// Input:40
	vec3 n_out40p0 = LIGHT0_DIRECTION;
	float n_out40p2 = n_out40p0.g;


// FloatOp:118
	float n_in118p1 = 6.36500;
	float n_out118p0 = n_out40p2 * n_in118p1;


// FloatFunc:54
	float n_out54p0 = min(max(n_out118p0, 0.0), 1.0);


// Mix:41
	vec3 n_out41p0 = mix(n_out52p0, n_out51p0, vec3(n_out54p0));


// Input:19
	vec3 n_out19p0 = LIGHT0_DIRECTION;


// VectorFunc:50
	vec3 n_out50p0 = -(n_out19p0);


// Input:13
	vec3 n_out13p0 = EYEDIR;


// Distance:21
	float n_out21p0 = distance(n_out50p0, n_out13p0);


// FloatParameter:17
	float n_out17p0 = MoonRadius;


// FloatOp:16
	float n_out16p0 = n_out21p0 / n_out17p0;


// FloatFunc:18
	float n_out18p0 = 1.0 - n_out16p0;


// Step:23
	float n_in23p0 = 0.00000;
	float n_out23p0 = step(n_in23p0, n_out18p0);


// Vector3Parameter:24
	vec3 moon_off_set = MoonOffset;


// VectorOp:25
	vec3 n_out25p0 = n_out13p0 + moon_off_set;


// Distance:26
	float n_out26p0 = distance(n_out25p0, n_out50p0);


// FloatOp:27
	float n_out27p0 = n_out26p0 / n_out17p0;


// FloatFunc:28
	float n_out28p0 = 1.0 - n_out27p0;


// Step:30
	float n_in30p0 = 0.00000;
	float n_out30p0 = step(n_in30p0, n_out28p0);


// FloatOp:29
	float n_out29p0 = n_out23p0 - n_out30p0;


// FloatFunc:36
	float n_out36p0 = min(max(n_out29p0, 0.0), 1.0);


// FloatParameter:113
	float n_out113p0 = MoonIntensity;


// FloatOp:112
	float n_out112p0 = n_out36p0 * n_out113p0;


// Input:2
	vec3 n_out2p0 = LIGHT0_DIRECTION;


// Distance:4
	float n_out4p0 = distance(n_out2p0, n_out13p0);


// FloatParameter:7
	float n_out7p0 = SunRadius;


// FloatOp:6
	float n_out6p0 = n_out4p0 / n_out7p0;


// FloatFunc:14
	float n_out14p0 = 1.0 - n_out6p0;


// Step:15
	float n_in15p0 = 0.00000;
	float n_out15p0 = step(n_in15p0, n_out14p0);


// FloatParameter:102
	float n_out102p0 = SunIntensity;


// FloatOp:101
	float n_out101p0 = n_out15p0 * n_out102p0;


// FloatOp:22
	float n_out22p0 = n_out112p0 + n_out101p0;


// FloatOp:151
	float n_out151p0 = n_out131p0 * n_out22p0;


// VectorOp:35
	vec3 n_out35p0 = n_out41p0 + vec3(n_out151p0);


// FloatFunc:117
	float n_out117p0 = abs(n_out40p2);


// FloatFunc:116
	float n_out116p0 = 1.0 - n_out117p0;


// FloatFunc:55
	float n_out55p0 = min(max(n_out116p0, 0.0), 1.0);


// Input:42
	vec3 n_out42p0 = EYEDIR;
	float n_out42p2 = n_out42p0.g;


// FloatOp:115
	float n_in115p1 = 2.53500;
	float n_out115p0 = n_out42p2 * n_in115p1;


// FloatFunc:43
	float n_out43p0 = abs(n_out115p0);


// FloatFunc:44
	float n_out44p0 = 1.0 - n_out43p0;


// FloatOp:46
	float n_out46p0 = n_out55p0 * n_out44p0;


// FloatFunc:114
	float n_out114p0 = min(max(n_out46p0, 0.0), 1.0);


// ColorParameter:48
	vec4 n_out48p0 = HorizonCol;


// VectorOp:47
	vec3 n_out47p0 = vec3(n_out114p0) * vec3(n_out48p0.xyz);


// VectorOp:49
	vec3 n_out49p0 = n_out35p0 + n_out47p0;


// VectorOp:67
	vec3 n_out67p0 = vec3(n_out152p0) + n_out49p0;


// ColorParameter:124
	vec4 n_out124p0 = CloudsInsideNight;


// FloatParameter:150
	float n_out150p0 = CloudsInsideIntensity;


// VectorOp:149
	vec3 n_out149p0 = vec3(n_out124p0.xyz) * vec3(n_out150p0);


// FloatParameter:167
	float n_out167p0 = CloudsEdgeIntensity;


// ColorParameter:125
	vec4 n_out125p0 = CloudsEdgeNight;


// VectorOp:168
	vec3 n_out168p0 = vec3(n_out167p0) * vec3(n_out125p0.xyz);


// FloatParameter:97
	float n_out97p0 = CloudsCutoffInside;


// FloatParameter:99
	float n_out99p0 = CloudsSmoothnessInside;


// FloatOp:98
	float n_out98p0 = n_out97p0 + n_out99p0;


// FloatFunc:140
	float n_out140p0 = min(max(n_out4p0, 0.0), 1.0);


// FloatFunc:139
	float n_out139p0 = min(max(n_out26p0, 0.0), 1.0);


// FloatOp:138
	float n_out138p0 = n_out140p0 + n_out139p0;


// FloatOp:147
	float n_out147p0 = n_out138p0 + n_out92p0;


// FloatOp:135
	float n_out135p0 = n_out147p0 * n_out93p0;


// FloatOp:136
	float n_in136p1 = 2.50000;
	float n_out136p0 = n_out135p0 * n_in136p1;


// FloatFunc:137
	float n_out137p0 = min(max(n_out136p0, 0.0), 1.0);


// SmoothStep:96
	float n_out96p0 = smoothstep(n_out97p0, n_out98p0, n_out137p0);


// Mix:126
	vec3 n_out126p0 = mix(n_out149p0, n_out168p0, vec3(n_out96p0));


// ColorParameter:110
	vec4 n_out110p0 = CloudEdgeDay;


// FloatParameter:166
	float n_out166p0 = CloudsInsideIntensity2;


// VectorOp:165
	vec3 n_out165p0 = vec3(n_out110p0.xyz) * vec3(n_out166p0);


// ColorParameter:109
	vec4 n_out109p0 = CloudInsideDay;


// FloatParameter:169
	float n_out169p0 = CloudsEdgeIntensity2;


// VectorOp:170
	vec3 n_out170p0 = vec3(n_out109p0.xyz) * vec3(n_out169p0);


// Mix:108
	vec3 n_out108p0 = mix(n_out165p0, n_out170p0, vec3(n_out96p0));


// Input:128
	vec3 n_out128p0 = LIGHT0_DIRECTION;
	float n_out128p2 = n_out128p0.g;


// FloatFunc:130
	float n_out130p0 = min(max(n_out128p2, 0.0), 1.0);


// Mix:127
	vec3 n_out127p0 = mix(n_out126p0, n_out108p0, vec3(n_out130p0));


// VectorOp:111
	vec3 n_out111p0 = n_out127p0 * vec3(n_out122p0);


// VectorOp:100
	vec3 n_out100p0 = n_out67p0 + n_out111p0;


// Output:0
	COLOR = n_out100p0;


}
