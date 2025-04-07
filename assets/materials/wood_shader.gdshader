shader_type spatial;

uniform sampler2D wood_texture : source_color;
uniform vec4 wood_color : source_color = vec4(0.76, 0.55, 0.26, 1.0);
uniform vec4 wood_color_dark : source_color = vec4(0.55, 0.35, 0.15, 1.0);
uniform float grain_strength = 0.4;
uniform float roughness : hint_range(0.0, 1.0) = 0.65;
uniform float specular : hint_range(0.0, 1.0) = 0.35;
uniform float rim_strength : hint_range(0.0, 1.0) = 0.2;
uniform bool selected = false;
uniform float selected_glow = 0.0;

void fragment() {
	// Sample the wood texture
	vec4 texture_color = texture(wood_texture, UV);
	
	// Create wood grain effect
	float noise = texture_color.r;
	float grain = smoothstep(0.4, 0.6, noise);
	vec4 base_color = mix(wood_color_dark, wood_color, grain);
	
	// Apply texture detail
	base_color = mix(base_color, texture_color, grain_strength);
	
	// Add selection glow effect
	if (selected || selected_glow > 0.0) {
		float glow_amount = selected ? 1.0 : selected_glow;
		vec3 glow_color = vec3(1.0, 0.8, 0.3) * glow_amount * 0.4;
		base_color.rgb += glow_color;
		EMISSION = glow_color;
	}
	
	// Output final color
	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	
	// Add subtle rim lighting
	float fresnel = pow(1.0 - dot(NORMAL, VIEW), 3.0);
	RIM = fresnel * rim_strength;
}
