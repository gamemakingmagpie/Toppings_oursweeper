shader_type canvas_item;

uniform vec4 color_a : source_color = vec4(1.0, 0.9, 0.0, 1.0);
uniform vec4 color_b : source_color = vec4(0.1, 0.1, 0.1, 1.0);
uniform float speed : hint_range(-5.0, 5.0) = 1.0;
uniform float density : hint_range(1.0, 50.0) = 10.0;
uniform float stripe_bias : hint_range(0.1, 0.9) = 0.5;

// New Uniform: Angle in degrees (0 to 360)
uniform float angle : hint_range(0.0, 360.0) = 45.0;

void fragment() {
	// 1. Convert degrees to radians
	float rad = radians(angle);
	
	// 2. Calculate the direction vector based on the angle
	// This determines the 'slope' of our stripes
	vec2 direction = vec2(cos(rad), sin(rad));
	
	// 3. Project the UV onto our direction vector
	// dot(UV, direction) gives us a 1D value that increases along our angle
	float projected_pos = dot(UV, direction);

	// 4. Add movement
	float moving_pos = projected_pos - (TIME * speed);

	// 5. Create repeating pattern
	float pattern_base = fract(moving_pos * density);

	// 6. Anti-aliased sharpening
	float pixel_smoothness = fwidth(moving_pos * density);
	float stripe_mask = smoothstep(stripe_bias - pixel_smoothness, stripe_bias + pixel_smoothness, pattern_base);

	vec4 final_color = mix(color_a, color_b, stripe_mask);

	COLOR = vec4(final_color.rgb, COLOR.a);
}