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
    \\uniform mat4 model;
    \\uniform mat4 view;
    \\uniform mat4 projection;
    \\
    \\void main() {
    \\  gl_Position = projection * view * model * vec4(aPos, 1.0);
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
    // positions      // colors      // tex coords
    // front
    0.5,  0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
    0.5,  -0.5, 0.5,  1.0, 1.0, 1.0, 1.0, 0.0,
    -0.5, -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 0.0,
    -0.5, 0.5,  0.5,  1.0, 1.0, 1.0, 0.0, 1.0,

    // back
    0.5,  0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 1.0,
    0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
    -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
    -0.5, 0.5,  -0.5, 1.0, 1.0, 1.0, 0.0, 1.0,

    // top
    0.5,  0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
    -0.5, 0.5,  -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
    -0.5, 0.5,  0.5,  1.0, 1.0, 1.0, 0.0, 1.0,

    // bottom
    0.5,  -0.5, 0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
    0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
    -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 1.0,

    // left
    -0.5, 0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
    -0.5, 0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
    -0.5, -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 1.0,

    // right
    0.5,  0.5,  0.5,  1.0, 1.0, 1.0, 1.0, 1.0,
    0.5,  0.5,  -0.5, 1.0, 1.0, 1.0, 1.0, 0.0,
    0.5,  -0.5, -0.5, 1.0, 1.0, 1.0, 0.0, 0.0,
    0.5,  -0.5, 0.5,  1.0, 1.0, 1.0, 0.0, 1.0,
};

const indices = [_]u32{
    // front
    0,  1,  3,
    1,  2,  3,

    // back
    4,  5,  7,
    5,  6,  7,

    // top
    8,  9,  11,
    9,  10, 11,

    // bottom
    12, 13, 15,
    13, 14, 15,

    // left
    16, 17, 19,
    17, 18, 19,

    // left
    20, 21, 23,
    21, 22, 23,
};

const positions = [_]zm.Vec3f{
    .{ 0.0, 0.0, 0.0 },
    .{ 2.0, 5.0, -15.0 },
    .{ -1.5, -2.2, -2.5 },
    .{ -3.8, -2.0, -12.3 },
    .{ 2.4, -0.4, -3.5 },
    .{ -1.7, 3.0, -7.5 },
    .{ 1.3, -2.0, -2.5 },
    .{ 1.5, 2.0, -2.5 },
    .{ 1.5, 0.2, -1.5 },
    .{ -1.3, 1.0, -1.5 },
};

var VAO: gl.uint = undefined;
var VBO: gl.uint = undefined;
var EBO: gl.uint = undefined;
var texture0: gl.uint = undefined;
var texture1: gl.uint = undefined;

var shader: Shader = undefined;
var start: u64 = 0;

pub fn init() void {
    start = rgfw.RGFW_getTimeNS();

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
        const view = zm.Mat4f.translationVec3(.{ 0.0, 0.0, -3.0 });

        shader.use();
        const idx = gl.GetUniformLocation(shader.program, "view");
        gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&view.data));
    }

    {
        const projection = zm.Mat4f.perspective(std.math.degreesToRadians(45.0), 800.0 / 600.0, 0.1, 100.0);

        shader.use();
        const idx = gl.GetUniformLocation(shader.program, "projection");
        gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&projection.data));
    }

    {
        gl.Enable(gl.DEPTH_TEST);
    }
}

pub fn render() void {
    const delta = rgfw.RGFW_getTimeNS() - start;
    const delta_second: f32 = @as(f32, @floatFromInt(delta)) / 1_000_000_000;

    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

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

        for (1.., positions) |i, p| {
            const angle = std.math.degreesToRadians(20.0 * @as(f32, @floatFromInt(i))) * delta_second;

            const rotation = zm.Quaternionf.fromAxisAngle(.{ 1.0, 0.3, 0.5 }, angle);
            const model = zm.Mat4f.translationVec3(p)
                .multiply(zm.Mat4f.fromQuaternion(rotation));

            const idx = gl.GetUniformLocation(shader.program, "model");
            gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&model.data));

            gl.DrawElements(gl.TRIANGLES, 6 * 6, gl.UNSIGNED_INT, 0);
        }
    }
}
