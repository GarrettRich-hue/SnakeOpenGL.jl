#version 150

in vec3 position;
in vec3 normal;
in vec2 texcoord;

out vec3 Normal;
out vec2 Texcoord;
out vec4 Pos;

uniform float texStretchT;
uniform float texStretchAxisT;
uniform vec3 p0;
uniform vec3 p1;
uniform vec3 d0;
uniform vec3 d1;
uniform float s0;
uniform float s1;
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;


void main()
{
    float t = position.z + 0.5f;
    float tm = 1.0f - t;
    float t2 = t*t;
    float tm2 = tm*tm;
    float t3 = t * t2;
    float tm3 = tm2 * tm;
    vec3 P0 = p0;
    vec3 P1 = p0+d0;
    vec3 P2 = p1-d1;
    vec3 P3 = p1;
    vec3 bezPos = tm3*P0 + 3*tm2*t*P1 + 3*tm*t2*P2 + t3*P3; 
    vec3 bezDir = normalize(3 * tm2 * (P1 - P0) + 6 * tm * t * (P2-P1) + 3*t2*(P3-P2));
    vec3 rightDir = normalize(cross(bezDir, vec3(0.0, 1.0, 0.0)));
    vec3 upDir = cross(rightDir, bezDir);
    float st = s1*t + s0*tm;
    mat4 bezTrans = mat4(vec4(rightDir*st, 0.0), vec4(upDir*st, 0.0), vec4(bezDir, 0.0), vec4(bezPos-position.z*bezDir, 1.0));
    vec4 pos = bezTrans*vec4(position, 1.0);
    gl_Position = proj*view*model*pos;
    Pos = model*pos;
    Normal = transpose(inverse(mat3(bezTrans*model))) * normal;

    Texcoord = vec2(texcoord.s, texStretchAxisT+(texcoord.t-texStretchAxisT)*texStretchT);
}

