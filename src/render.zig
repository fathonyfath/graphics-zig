const std = @import("std");
const gl = @import("gl");
const Shader = @import("Shader.zig");
const rgfw = @import("rgfw.zig").rgfw;

const vertex_shader_source =
    \\#version 330 core
    \\layout(location = 0) in vec3 aPos;
    \\layout(location = 1) in vec3 aColor;
    \\
    \\out vec3 ourColor;
    \\
    \\void main() {
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\  ourColor = aColor;
    \\}
    \\
;

const fragment_shader_source =
    \\#version 330 core
    \\in vec3 ourColor;
    \\
    \\out vec4 FragColor;
    \\
    \\void main() {
    \\  FragColor = vec4(ourColor, 1.0);
    \\}
    \\
;

const vertices_triangle = [_]f32{
    // positions     // colors
    0.5,  -0.5, 0.0, 1.0, 0.0, 0.0,
    -0.5, -0.5, 0.0, 0.0, 1.0, 0.0,
    0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
};

const indices_triangle = [_]u32{
    0, 1, 2,
};

var VAO: gl.uint = undefined;
var VBO: gl.uint = undefined;
var EBO: gl.uint = undefined;

var shader: Shader = undefined;
var minus: u64 = 0;

pub fn init() void {
    minus = rgfw.RGFW_getTimeNS();

    {
        gl.GenBuffers(1, @ptrCast(&VBO));

        gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
        defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

        gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices_triangle)), &vertices_triangle, gl.STATIC_DRAW);
    }

    {
        gl.GenBuffers(1, @ptrCast(&EBO));

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices_triangle)), &indices_triangle, gl.STATIC_DRAW);
    }

    {
        gl.GenVertexArrays(1, @ptrCast(&VAO));

        gl.BindVertexArray(VAO);
        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        defer {
            gl.BindVertexArray(0);
            defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);
        }

        {
            gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
            defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

            gl.EnableVertexAttribArray(0);
            gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 0);
            gl.EnableVertexAttribArray(1);
            gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
        }
    }

    shader = Shader.create(vertex_shader_source, fragment_shader_source);
}

pub fn render() void {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    const elapsed: u64 = rgfw.RGFW_getTimeNS() - minus;
    const second_float: f32 = @as(f32, @floatFromInt(elapsed)) / 1_000_000_000;
    const green_value = @sin(second_float) / 2.0 + 0.5;

    const location = gl.GetUniformLocation(shader.program, "ourColor");

    shader.use();
    gl.Uniform4f(location, 0.0, green_value, 0.0, 1.0);

    {
        gl.BindVertexArray(VAO);
        defer gl.BindVertexArray(0);

        gl.DrawElements(gl.TRIANGLES, 3, gl.UNSIGNED_INT, 0);
    }
}
