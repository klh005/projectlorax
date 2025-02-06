// Godot 4.3-compliant shader
shader_type spatial;

// Albedo texture (sRGB color space)
uniform sampler2D albedo_tex : source_color;

// Normal map (tangent space)
uniform sampler2D normal_tex : hint_normal;

// Roughness map (linear color space, no hint needed)
uniform sampler2D roughness_tex;

// Metallic map (linear color space, no hint needed)
uniform sampler2D metallic_tex;

void fragment() {
    // Sample textures
    vec4 albedo = texture(albedo_tex, UV);
    vec3 normal = texture(normal_tex, UV).xyz * 2.0 - 1.0;
    float roughness = texture(roughness_tex, UV).r;
    float metallic = texture(metallic_tex, UV).r;

    // Assign outputs
    ALBEDO = albedo.rgb;
    NORMAL = normal;
    ROUGHNESS = roughness;
    METALLIC = metallic;
}