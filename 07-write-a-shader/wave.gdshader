shader_type canvas_item;

uniform float speed = 3.0;
uniform float strength : hint_range(0.0, 0.1) = 0.05;
uniform vec4 tint : source_color = vec4(0.949, 0.549, 0.157, 1.0);

void fragment() {
	vec2 moved = UV;
	moved.x += sin(moved.y * 10.0 + TIME * speed) * strength * UV.y;
	COLOR = texture(TEXTURE, moved) * tint;
}
