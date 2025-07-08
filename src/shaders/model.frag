# version 150

in vec2 Texcoord;
in vec3 Normal;
in vec4 Pos;

out vec4 outColor;

uniform sampler2D tex;

void main()
{
    vec3 lightDirection = normalize(vec3(1.0, -2.0, -1.0));
    vec4 diffuseLight = vec4(vec3(0.8), 1.0);
    vec4 ambientLight = vec4(vec3(0.3),1.0);
    vec4 specularLight = vec4(vec3(0.8), 1.0);

    vec3 cameraPosition = vec3(4, 10.6568, 4);

    float shininess = 32;

    vec3 norm = normalize(Normal);
    vec4 objectCol = texture(tex, Texcoord);

    vec4 diffuse = max(0.0, dot(-lightDirection, norm)) * diffuseLight;
    vec4 ambient = ambientLight;
    vec3 viewDirection = normalize(Pos.xyz - cameraPosition);
    vec3 reflectDir = reflect(-lightDirection, norm);
    vec4 specular = pow(max(0.0, dot(viewDirection, reflectDir)), shininess) * specularLight;
    outColor = vec4(objectCol.rgb,1.0) * (ambient+diffuse)+ specular;
}
