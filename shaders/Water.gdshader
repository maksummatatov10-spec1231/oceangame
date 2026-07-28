shader_type spatial;

global uniform vec3 ocean_pos; // Global shader value for the player position
// Godot 4.3 requires screen and depth textures to be declared explicitly.
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform vec3 albedo : source_color = vec3(0.0,0.32,0.43);
uniform vec3 albedo2 : source_color = vec3(0.0,0.47,0.76);
uniform float metallic : hint_range(0.0, 1.0) = 0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform sampler2D wave; // Noise wave texture
uniform sampler2D wave_bump; // Normal bump map version of the noise wave texture
uniform sampler2D texture_normal; // Additional normal noise
uniform sampler2D texture_normal2; // Additional normal noise
uniform vec2 wave_direction = vec2(0.5,-0.2); // Direction of wave 1
uniform vec2 wave_direction2 = vec2(-0.5,0.5); // Direction of wave 2
uniform float time_scale : hint_range(0.0, 0.2, 0.005) = 0.1; // Rate of movement multiplied by TIME
uniform float noise_scale = 20.0; // Scale of the wave noise texture
uniform float height_scale = 2.0; // Mulitply the normal height values

// Depth color
uniform vec3 color_deep : source_color = vec3(0.11,0.29,0.33); // Deep depth color
uniform vec3 color_shallow : source_color = vec3(0.0,0.47,0.76); // Shallow depth color
uniform float beers_law = 2.0; // Beer's law application
uniform float depth_offset = 1.5; // Offset

// Edge detection
uniform float edge_scale = 0.3;
uniform float near = 1.0;
uniform float far = 100.0;
uniform vec3 edge_color : source_color = vec3(1.0,1.0,1.0);

// Varying variables
varying float height;
varying vec3 world_pos;
varying float vertex_distance;
varying float vertex_distance_clamped;
varying vec2 vertex_pos;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

float edge(float depth){
	depth = 2.0 * depth - 1.0;
	return near * far / (far + depth * (near - far));
}

float waveheight(vec2 offset, int mode) {
	float h1 = 0.0; // Wave1 texture height
	float h2 = 0.0; // Wave2 texture height
	float hmix = 0.0; // Wave texture heights mixed
	switch (mode) {
		case 0: // For getting only the Wave1 height
			h1 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction) * time_scale).r;
			return h1;
		case 1: // For getting only the Wave2 height
			h2 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction2) * time_scale).r;
			return h2;
		case 2: // For getting both Wave1 and Wave2 heights and getting the average
			h1 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction) * time_scale).r;
			h2 = texture(wave, (world_pos.xz + offset) / noise_scale + (TIME * wave_direction2) * time_scale).r;
			hmix = mix(h1, h2, 0.5);
			return hmix;
	}
	return 0.0;
}

// Four Gerstner-style vertical swells. Their equations are mirrored in
// ocean_game.gd so the boat rides exactly the same water surface.
float large_waves(vec2 p, float t) {
	float a = 1.80 * sin(dot(p, vec2(0.95, 0.31)) * (6.283185 / 21.0) - t * 1.50);
	float b = 1.15 * sin(dot(p, vec2(-0.38, 0.925)) * (6.283185 / 13.0) - t * 2.10);
	float c = 0.75 * sin(dot(p, vec2(0.72, -0.694)) * (6.283185 / 7.0) - t * 2.80);
	float d = 0.30 * sin(dot(p, vec2(-0.16, 0.987)) * (6.283185 / 3.5) - t * 4.00);
	return a + b + c + d;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vertex_distance = clamp(distance(world_pos, ocean_pos), 0.0, 210.0);
	vertex_distance_clamped = vertex_distance / 210.0;

	// Fine, noisy ripples still come from the supplied NoiseTexture2D.
	float height_mix = waveheight(vec2(0.0), 2);
	float texture_wave = (height_mix - 0.5) * height_scale * 0.32;
	float ocean_swell = large_waves(world_pos.xz, TIME);
	// Keep the close 95 m fully detailed, then fade waves only at the distant
	// LOD horizon. The parent tile grid continually follows the ship.
	float wave_falloff = 1.0 - smoothstep(95.0, 190.0, vertex_distance);
	height = (texture_wave + ocean_swell) * wave_falloff;
	VERTEX.y += height;
}

void fragment() {
	// The supplied shader's original depth/edge blend painted empty ocean white:
	// with no sea floor in the depth buffer it selected edge_color around the player.
	// Keep the asset's procedural wave and normal textures, but use a stable
	// deep-water surface colour for open ocean.
	vec2 time = (TIME * wave_direction) * time_scale;
	vec2 time2 = (TIME * wave_direction2) * time_scale;
	vec3 normal_blend = mix(
		texture(texture_normal, world_pos.xz / 10.0 + time / 10.0).rgb,
		texture(texture_normal2, world_pos.xz / 10.0 + time2 / 10.0).rgb,
		0.5
	);
	vec3 wave_normal_blend = mix(
		texture(wave_bump, world_pos.xz / noise_scale + time).xyz,
		texture(wave_bump, world_pos.xz / noise_scale + time2).xyz,
		0.3
	);
	float rim = fresnel(5.0, NORMAL, VIEW);
	float moving_crest = clamp(wave_normal_blend.r * 0.22, 0.0, 0.22);
	float crest_foam = smoothstep(2.35, 3.75, height) * 0.33;
	vec3 water_color = mix(albedo, albedo2, clamp(rim * 0.72 + moving_crest, 0.0, 1.0));
	ALBEDO = mix(water_color, vec3(0.72, 0.88, 0.92), crest_foam);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = mix(wave_normal_blend, normal_blend, 0.5);
	SPECULAR = 0.62;
}
