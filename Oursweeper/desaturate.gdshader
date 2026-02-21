shader_type canvas_item;

// 0.0 = Full Color, 1.0 = Fully Grayscale
uniform float saturation : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Standard Rec. 709 luminance weights for human eye perception
    float luminance = dot(tex_color.rgb, vec3(0.2126, 0.7152, 0.0722));
    vec3 grayscale = vec3(luminance);
    
    // Linearly interpolate between the original color and the grayscale version
    vec3 final_color = mix(tex_color.rgb, grayscale, saturation);
    
    COLOR = vec4(final_color, tex_color.a);
}