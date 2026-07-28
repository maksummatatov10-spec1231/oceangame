/*
  Ocean Voyage integration of the MIT-licensed UnionBytes Realistic Water
  shader assets. Uses its Water_N_A, Water_N_B, Water_UV and Foam textures.
  See ThirdParty/realistic-water/LICENSE.md and AUTHORS.md.
*/
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx, depth_draw_always;

uniform sampler2D normalmap_a_sampler : hint_normal;
uniform sampler2D normalmap_b_sampler : hint_normal;
uniform sampler2D uv_sampler : hint_default_black;
uniform sampler2D foam_sampler : hint_default_black;

uniform vec3 deep_color : source_color = vec3(0.008, 0.075, 0.15);
uniform vec3 surface_color : source_color = vec3(0.025, 0.31, 0.48);
uniform vec3 crest_color : source_color = vec3(0.63, 0.88, 0.93);
uniform float normal_strength : hint_range(0.0, 2.0) = 1.15;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.48;

varying float wave_height;
varying vec3 ocean_world_pos;

const float TAU = 6.28318530718;

// A Gerstner-style wave. Parameters are direction, amplitude, wavelength and
// phase speed. The identical vertical equation exists in ocean_game.gd.
float gerstner_height(vec2 position, vec2 direction, float amplitude, float wavelength, float speed) {
    float phase = TAU / wavelength * dot(normalize(direction), position) - TIME * speed;
    return amplitude * sin(phase);
}

float ocean_height(vec2 position) {
    float h = 0.0;
    h += gerstner_height(position, vec2(0.92, 0.38), 1.45, 25.0, 2.40);
    h += gerstner_height(position, vec2(-0.35, 0.94), 1.10, 17.0, 3.10);
    h += gerstner_height(position, vec2(0.72, -0.69), 0.75, 11.0, 4.00);
    h += gerstner_height(position, vec2(-0.82, -0.57), 0.48, 7.0, 5.20);
    h += gerstner_height(position, vec2(0.15, 0.99), 0.27, 4.3, 6.50);
    h += gerstner_height(position, vec2(-0.98, 0.20), 0.16, 2.2, 8.00);
    return h;
}

vec2 wave_slope(vec2 position, vec2 direction, float amplitude, float wavelength, float speed) {
    vec2 d = normalize(direction);
    float phase = TAU / wavelength * dot(d, position) - TIME * speed;
    return d * amplitude * TAU / wavelength * cos(phase);
}

vec2 ocean_slope(vec2 position) {
    vec2 slope = vec2(0.0);
    slope += wave_slope(position, vec2(0.92, 0.38), 1.45, 25.0, 2.40);
    slope += wave_slope(position, vec2(-0.35, 0.94), 1.10, 17.0, 3.10);
    slope += wave_slope(position, vec2(0.72, -0.69), 0.75, 11.0, 4.00);
    slope += wave_slope(position, vec2(-0.82, -0.57), 0.48, 7.0, 5.20);
    slope += wave_slope(position, vec2(0.15, 0.99), 0.27, 4.3, 6.50);
    slope += wave_slope(position, vec2(-0.98, 0.20), 0.16, 2.2, 8.00);
    return slope;
}

void vertex() {
    ocean_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    wave_height = ocean_height(ocean_world_pos.xz);
    VERTEX.y += wave_height;
    vec2 slope = ocean_slope(ocean_world_pos.xz);
    NORMAL = normalize(vec3(-slope.x, 1.0, -slope.y));
}

void fragment() {
    // The downloaded project's three moving texture layers remove repeating
    // patterns and provide detailed ripples independently of the large waves.
    vec2 world_uv = ocean_world_pos.xz;
    vec2 flow_a = vec2(0.035, 0.022) * TIME;
    vec2 flow_b = vec2(-0.021, 0.041) * TIME;
    vec2 distortion = (texture(uv_sampler, world_uv * 0.035 + flow_b).rg * 2.0 - 1.0) * 0.18;
    vec3 normal_a = texture(normalmap_a_sampler, world_uv * 0.075 + flow_a + distortion).rgb;
    vec3 normal_b = texture(normalmap_b_sampler, world_uv * 0.19 + flow_b - distortion).rgb;
    NORMAL_MAP = normalize(mix(normal_a * 2.0 - 1.0, normal_b * 2.0 - 1.0, 0.48)) * 0.5 + 0.5;
    NORMAL_MAP_DEPTH = normal_strength;

    float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 4.2);
    float crest = smoothstep(1.55, 3.45, wave_height);
    float foam = texture(foam_sampler, world_uv * 0.16 + flow_a * 1.8).r;
    foam = smoothstep(0.50, 0.82, foam) * crest * foam_strength;
    vec3 water = mix(deep_color, surface_color, fresnel * 0.92 + 0.08);
    ALBEDO = mix(water, crest_color, foam);
    METALLIC = 0.18;
    ROUGHNESS = mix(0.10, 0.26, foam);
    SPECULAR = 0.82;
}
