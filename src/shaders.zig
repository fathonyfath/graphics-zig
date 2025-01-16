const Shader = @import("Shader.zig");

const vertex_shader_source =
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

const fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\uniform vec3 objectColor;
    \\uniform vec3 lightColor;
    \\
    \\void main() {
    \\  FragColor = vec4(objectColor * lightColor, 1.0);
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
