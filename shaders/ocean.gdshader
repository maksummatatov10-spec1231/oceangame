shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 deep_color : source_color = vec3(0.008, 0.075, 0.16);
uniform vec3 crest_color : source_color = vec3(0.03, 0.47, 0.70);
uniform float wave_height = 0.58;
uniform float wave_scale = 0.115;
uniform float wave_speed = 0.8;
varying vec3 ocean_world_pos;

float waves(vec2 p) {
    float t = TIME * wave_speed;
    float a = sin(p.x * wave_scale + t) * 0.52;
    float b = sin(p.y * wave_scale * 1.37 - t * 0.78) * 0.29;
    float c = sin((p.x + p.y) * wave_scale * 0.62 + t * 1.25) * 0.19;
    return a + b + c;
}

void vertex() {
    vec2 world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
    VERTEX.y += waves(world_xz) * wave_height;
    ocean_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    float bands = sin((ocean_world_pos.x + ocean_world_pos.z) * 0.08 + TIME) * 0.5 + 0.5;
    float fresnel = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.5);
    ALBEDO = mix(deep_color, crest_color, fresnel * 0.82 + bands * 0.08);
    ROUGHNESS = 0.13;
    METALLIC = 0.08;
    SPECULAR = 0.9;
}
