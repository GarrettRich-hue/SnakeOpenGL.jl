# version 150

in vec2 Texcoord;
in vec3 Normal;
in vec4 Pos;

out vec4 outColor;

uniform sampler2D tex;
uniform vec3 cameraPosition;
uniform vec3 lightDirection;
uniform vec4 diffuseLight;
uniform vec4 ambientLight;
uniform vec4 specularLight;

void main()
{

    float shininess = 32;

    vec3 norm = normalize(Normal);
    vec4 objectCol = texture(tex, Texcoord);

    vec4 diffuse = max(0.0, dot(-lightDirection, norm)) * diffuseLight;
    vec4 ambient = ambientLight;
    vec3 viewDirection = normalize((Pos).xyz);
    vec3 reflectDir = reflect(-lightDirection, norm);
    vec4 specular = pow(max(0.0, dot(viewDirection, reflectDir)), shininess) * specularLight;
    outColor = vec4(objectCol.rgb,1.0) * (ambient+diffuse)+ specular;
}
