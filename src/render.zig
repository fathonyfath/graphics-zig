const std = @import("std");
const gl = @import("gl");
const zm = @import("zm");
const Shader = @import("Shader.zig");
const rgfw = @import("rgfw.zig").rgfw;
const stb_image = @import("stb_image.zig");

const vertex_shader_source =
    \\#version 330 core
    \\layout(location = 0) in vec3 aPos;
    \\layout(location = 1) in vec3 aColor;
    \\layout(location = 2) in vec2 aTexCoord;
    \\
    \\out vec3 ourColor;
    \\out vec2 TexCoord;
    \\
    \\uniform mat4 transform;
    \\
    \\void main() {
    \\  gl_Position = transform * vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\  ourColor = aColor;
    \\  TexCoord = aTexCoord;
    \\}
    \\
;

const fragment_shader_source =
    \\#version 330 core
    \\in vec3 ourColor;
    \\in vec2 TexCoord;
    \\
    \\out vec4 FragColor;
    \\
    \\uniform sampler2D texture0;
    \\uniform sampler2D texture1;
    \\
    \\void main() {
    \\  FragColor = mix(texture(texture0, TexCoord), texture(texture1, TexCoord), 0.2) * vec4(ourColor, 1.0);
    \\}
    \\
;

const vertices = [_]f32{
    // positions     // colors      // tex coords
    0.5,  0.5,  0.0, 1.0, 0.0, 0.0, 1.0, 1.0,
    0.5,  -0.5, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0,
    -0.5, -0.5, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
    -0.5, 0.5,  0.0, 1.0, 1.0, 0.0, 0.0, 1.0,
};

const indices = [_]u32{
    0, 1, 3,
    1, 2, 3,
};

var VAO: gl.uint = undefined;
var VBO: gl.uint = undefined;
var EBO: gl.uint = undefined;
var texture0: gl.uint = undefined;
var texture1: gl.uint = undefined;

var shader: Shader = undefined;
var minus: u64 = 0;

pub fn init() void {
    minus = rgfw.RGFW_getTimeNS();

    {
        gl.GenBuffers(1, @ptrCast(&VBO));

        gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
        defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

        gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), &vertices, gl.STATIC_DRAW);
    }

    {
        gl.GenBuffers(1, @ptrCast(&EBO));

        gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
        defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

        gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices)), &indices, gl.STATIC_DRAW);
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
            gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 0);
            gl.EnableVertexAttribArray(1);
            gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 3 * @sizeOf(f32));
            gl.EnableVertexAttribArray(2);
            gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
        }
    }

    shader = Shader.create(vertex_shader_source, fragment_shader_source);

    {
        var width: i32 = undefined;
        var height: i32 = undefined;
        var num_in_channels: i32 = undefined;

        const data = stb_image.loadImage("container.jpg", &width, &height, &num_in_channels);
        defer stb_image.freeImage(data);

        gl.GenTextures(1, @ptrCast(&texture0));

        gl.BindTexture(gl.TEXTURE_2D, texture0);
        defer gl.BindTexture(gl.TEXTURE_2D, 0);

        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, data);
        gl.GenerateMipmap(gl.TEXTURE_2D);
    }

    {
        var width: i32 = undefined;
        var height: i32 = undefined;
        var num_in_channels: i32 = undefined;

        const data = stb_image.loadImage("awesomeface.png", &width, &height, &num_in_channels);
        defer stb_image.freeImage(data);

        gl.GenTextures(1, @ptrCast(&texture1));

        gl.BindTexture(gl.TEXTURE_2D, texture1);
        defer gl.BindTexture(gl.TEXTURE_2D, 0);

        gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
        gl.GenerateMipmap(gl.TEXTURE_2D);
    }

    {
        shader.use();
        const texture0_pos = gl.GetUniformLocation(shader.program, "texture0");
        gl.Uniform1i(texture0_pos, 0);
        const texture1_pos = gl.GetUniformLocation(shader.program, "texture1");
        gl.Uniform1i(texture1_pos, 1);
    }

    {
        shader.use();
        const trans = zm.Mat4f.identity()
            .multiply(zm.Mat4f.rotation(.{ 0.0, 0.0, 1.0 }, std.math.degreesToRadians(90.0)))
            .multiply(zm.Mat4f.scaling(0.5, 0.5, 0.5));
        const transform_pos = gl.GetUniformLocation(shader.program, "transform");
        gl.UniformMatrix4fv(transform_pos, 1, gl.TRUE, @ptrCast(&trans.data));
    }
}

pub fn render() void {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    {
        gl.ActiveTexture(gl.TEXTURE0);
        gl.BindTexture(gl.TEXTURE_2D, texture0);
        defer gl.BindTexture(gl.TEXTURE_2D, 0);

        gl.ActiveTexture(gl.TEXTURE1);
        gl.BindTexture(gl.TEXTURE_2D, texture1);
        defer gl.BindTexture(gl.TEXTURE_2D, 0);

        shader.use();

        gl.BindVertexArray(VAO);
        defer gl.BindVertexArray(0);

        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, 0);
    }
}
