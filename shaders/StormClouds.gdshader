// Lightweight procedural storm-cloud deck for Godot 4.3.
// Inspired by the layered-density/raymarch cloud approach, but rendered as
// three scrolling cloud layers so it remains practical on Compatibility GPU.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform float storm_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec3 cloud_dark : source_color = vec3(0.055, 0.075, 0.11);
uniform vec3 cloud_light : source_color = vec3(0.23, 0.29, 0.36);
uniform float layer_seed = 0.0;
varying vec3 cloud_world_position;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.55;
    for (int octave = 0; octave < 5; octave++) {
        value += amplitude * noise(p);
        p = p * 2.03 + vec2(13.1, 7.7);
        amplitude *= 0.5;
    }
    return value;
}

void vertex() {
    cloud_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    vec2 p = cloud_world_position.xz * 0.012 + vec2(TIME * 0.010, TIME * 0.004) + layer_seed;
    float macro = fbm(p);
    float detail = fbm(p * 3.0 - TIME * 0.015);
    float density = mix(macro, detail, 0.32);
    float threshold = mix(0.82, 0.39, storm_amount);
    float alpha = smoothstep(threshold, threshold + 0.18, density) * storm_amount * 0.88;
    ALBEDO = mix(cloud_light, cloud_dark, density);
    ALPHA = alpha;
}
