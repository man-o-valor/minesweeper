uniform float time;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    float x = screen_coords.x;
    float y = screen_coords.y;
    float v = fract(sin(dot(vec2(x * 0.01, y * 0.01 + time), vec2(12.9898,78.233))) * 43758.5453);
    float flicker = sin(time * 10.0) * 0.03 + 0.97;
    float brightness = v * flicker;
    brightness = clamp(brightness, 0.3, 1.0);
    vec4 staticColor = vec4(vec3(brightness), 1.0);
    return staticColor;
}