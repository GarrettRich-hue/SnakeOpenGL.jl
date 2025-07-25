#version 150

in vec3 position;
in vec3 normal;
in vec2 texcoord;

out vec3 Normal;
out vec2 Texcoord;
out vec4 Pos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    Texcoord = texcoord;
    gl_Position = proj * view * model * vec4(position, 1.0);
    Normal = transpose(inverse(mat3(model)))*normal;
    Pos = model * vec4(position, 1.0);
}
