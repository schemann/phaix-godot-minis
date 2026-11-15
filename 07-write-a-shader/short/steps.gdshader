shader_type canvas_item;
// The Short's stages of the lesson's shader: the lines of wave.gdshader one at a time, as the voice builds them up.

uniform float uv_view : hint_range(0.0, 1.0) = 0.0; // 1: paint UV itself as colour (red to the right, green downwards)
uniform float shift = 0.0;                          // a small number added to the horizontal UV
uniform float strength = 0.0;                       // how far sin(...) swings it: the lesson's own uniform name
uniform float rows = 0.0;                           // the vertical position inside the sine: 0 = none, 10.0 = the lesson
uniform float speed = 3.0;
uniform vec4 tint : source_color = vec4(0.949, 0.549, 0.157, 1.0);

void fragment() {
	vec2 moved = UV;
	moved.x += shift + sin(moved.y * rows + TIME * speed) * strength;
	vec4 picture = texture(TEXTURE, moved) * tint;
	vec4 position = vec4(UV.x, UV.y, 0.25, mix(0.35, 1.0, texture(TEXTURE, UV).a));
	COLOR = mix(picture, position, uv_view);
}
