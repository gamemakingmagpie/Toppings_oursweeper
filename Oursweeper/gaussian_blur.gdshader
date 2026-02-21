shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_scale : hint_range(0.0, 5.0) = 1.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 size = SCREEN_PIXEL_SIZE * blur_scale;

    // 9-tap Gaussian weights
    float weight[5] = float[](0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216);

    // Start with the center pixel
    vec3 result = texture(screen_texture, uv).rgb * weight[0];

    // Sample neighbors in both directions (Horizontal & Vertical mix)
    // For a "perfect" blur, you'd run this in two separate passes,
    // but this multi-directional version works for simple UI effects.
    for(int i = 1; i < 5; i++) {
        float offset = float(i);
        result += texture(screen_texture, uv + vec2(size.x * offset, 0.0)).rgb * weight[i];
        result += texture(screen_texture, uv - vec2(size.x * offset, 0.0)).rgb * weight[i];
        result += texture(screen_texture, uv + vec2(0.0, size.y * offset)).rgb * weight[i];
        result += texture(screen_texture, uv - vec2(0.0, size.y * offset)).rgb * weight[i];
    }

    COLOR = vec4(result / 3.0, 1.0); // Normalize the brightness
}