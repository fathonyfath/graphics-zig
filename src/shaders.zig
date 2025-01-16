const Shader = @import("Shader.zig");

const vertex_shader_source =
    \\#version 330 core
    \\layout(location = 0) in vec3 aPos;
    \\layout(location = 1) in vec3 aNormal;
    \\
    \\out vec3 FragPos;
    \\out vec3 Normal;
    \\
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 projection;
    \\
    \\void main() {
    \\  FragPos = vec3(model * vec4(aPos, 1.0));
    \\  Normal = mat3(transpose(inverse(model))) * aNormal;
    \\
    \\  gl_Position = projection * view * model * vec4(aPos, 1.0);
    \\}
    \\
;

const fragment_shader_source =
    \\#version 330 core
    \\in vec3 FragPos;
    \\in vec3 Normal;
    \\
    \\out vec4 FragColor;
    \\
    \\uniform vec3 lightPos;
    \\uniform vec3 viewPos;
    \\uniform vec3 objectColor;
    \\uniform vec3 lightColor;
    \\
    \\void main() {
    \\  // ambient color
    \\  float ambientStrength = 0.1;
    \\  vec3 ambient = ambientStrength * lightColor;
    \\
    \\  // diffuse color
    \\  vec3 norm = normalize(Normal);
    \\  vec3 lightDir = normalize(lightPos - FragPos);
    \\  float diff = max(dot(norm, lightDir), 0.0);
    \\  vec3 diffuse = diff * lightColor;
    \\
    \\  // specular color
    \\  float specularStrength = 0.5;
    \\  vec3 viewDir = normalize(viewPos - FragPos);
    \\  vec3 reflectDir = reflect(-lightDir, norm);
    \\  float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32);
    \\  vec3 specular = specularStrength * spec * lightColor;
    \\
    \\  vec3 result = (ambient + diffuse + specular) * objectColor;
    \\  FragColor = vec4(result, 1.0);
    \\}
    \\
;

const light_vertex_shader_source =
    \\#version 330 core
    \\layout(location = 0) in vec3 aPos;
    \\
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 projection;
    \\
    \\void main() {
    \\  gl_Position = projection * view * model * vec4(aPos, 1.0);
    \\}
    \\
;

const light_fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main() {
    \\  FragColor = vec4(1.0);
    \\}
    \\
;

pub var object_shader: Shader = undefined;
pub var light_shader: Shader = undefined;

pub fn initialize() void {
    object_shader = Shader.create(vertex_shader_source, fragment_shader_source);
    light_shader = Shader.create(light_vertex_shader_source, light_fragment_shader_source);
}

pub fn shaders() [2]Shader {
    return .{ object_shader, light_shader };
}
