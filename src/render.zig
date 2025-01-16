const std = @import("std");
const gl = @import("gl");
const zm = @import("zm");
const Shader = @import("Shader.zig");
const Camera = @import("Camera.zig");
const rgfw = @import("rgfw.zig").rgfw;
const stb_image = @import("stb_image.zig");
const shaders = @import("shaders.zig");

const vertices = [_]f32{
    // positions      // normal
    // front
    0.5,  0.5,  0.5,  0.0,  0.0,  1.0,
    0.5,  -0.5, 0.5,  0.0,  0.0,  1.0,
    -0.5, -0.5, 0.5,  0.0,  0.0,  1.0,
    -0.5, 0.5,  0.5,  0.0,  0.0,  1.0,

    // back
    0.5,  0.5,  -0.5, 0.0,  0.0,  -1.0,
    0.5,  -0.5, -0.5, 0.0,  0.0,  -1.0,
    -0.5, -0.5, -0.5, 0.0,  0.0,  -1.0,
    -0.5, 0.5,  -0.5, 0.0,  0.0,  -1.0,

    // top
    0.5,  0.5,  0.5,  0.0,  1.0,  0.0,
    0.5,  0.5,  -0.5, 0.0,  1.0,  0.0,
    -0.5, 0.5,  -0.5, 0.0,  1.0,  0.0,
    -0.5, 0.5,  0.5,  0.0,  1.0,  0.0,

    // bottom
    0.5,  -0.5, 0.5,  0.0,  -1.0, 0.0,
    0.5,  -0.5, -0.5, 0.0,  -1.0, 0.0,
    -0.5, -0.5, -0.5, 0.0,  -1.0, 0.0,
    -0.5, -0.5, 0.5,  0.0,  -1.0, 0.0,

    // left
    -0.5, 0.5,  0.5,  -1.0, 0.0,  0.0,
    -0.5, 0.5,  -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, -0.5, -1.0, 0.0,  0.0,
    -0.5, -0.5, 0.5,  -1.0, 0.0,  0.0,

    // right
    0.5,  0.5,  0.5,  1.0,  0.0,  0.0,
    0.5,  0.5,  -0.5, 1.0,  0.0,  0.0,
    0.5,  -0.5, -0.5, 1.0,  0.0,  0.0,
    0.5,  -0.5, 0.5,  1.0,  0.0,  0.0,
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

var VAO: gl.uint = undefined;
var VBO: gl.uint = undefined;
var EBO: gl.uint = undefined;
var texture0: gl.uint = undefined;
var texture1: gl.uint = undefined;

var start: u64 = 0;
var delta: u64 = 0;
var delta_second: f32 = 0.0;

var camera: Camera = undefined;

var light_position = zm.Vec3f{ 0.0, 0.0, 0.0 };

pub fn init() void {
    shaders.initialize();
    camera = Camera.createWithDefaults(.{ 0.0, 0.0, 3.0 }, zm.vec.up(f32));
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
            gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 0);
            gl.EnableVertexAttribArray(1);
            gl.VertexAttribPointer(1, 3, gl.FLOAT, gl.FALSE, 6 * @sizeOf(f32), 3 * @sizeOf(f32));
            // gl.EnableVertexAttribArray(2);
            // gl.VertexAttribPointer(2, 2, gl.FLOAT, gl.FALSE, 8 * @sizeOf(f32), 6 * @sizeOf(f32));
        }
    }

    {
        const view = camera.getViewMatrix();

        for (shaders.shaders()) |shader| {
            shader.use();
            const idx = gl.GetUniformLocation(shader.program, "view");
            gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&view.data));
        }
    }

    {
        const projection = zm.Mat4f.perspective(std.math.degreesToRadians(45.0), 800.0 / 600.0, 0.1, 100.0);

        for (shaders.shaders()) |shader| {
            shader.use();
            const idx = gl.GetUniformLocation(shader.program, "projection");
            gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&projection.data));
        }
    }

    {
        shaders.object_shader.use();
        {
            const idx = gl.GetUniformLocation(shaders.object_shader.program, "objectColor");
            gl.Uniform3fv(idx, 1, @ptrCast(&zm.Vec3f{ 1.0, 0.5, 0.31 }));
        }
        {
            const idx = gl.GetUniformLocation(shaders.object_shader.program, "lightColor");
            gl.Uniform3fv(idx, 1, @ptrCast(&zm.Vec3f{ 1.0, 1.0, 1.0 }));
        }
    }

    {
        gl.Enable(gl.DEPTH_TEST);
    }
}

pub fn input(input_state: [4]bool, mouse_pos_offset: [2]i32) void {
    const w_pressed = input_state[0];
    const a_pressed = input_state[1];
    const s_pressed = input_state[2];
    const d_pressed = input_state[3];

    const sensitivity: f32 = 0.15;

    var x_offset: f32 = @floatFromInt(mouse_pos_offset[0]);
    var y_offset: f32 = @floatFromInt(mouse_pos_offset[1]);

    x_offset *= sensitivity;
    y_offset *= sensitivity;

    camera.rotate(x_offset, y_offset);

    const camera_speed: f32 = 0.05;
    const camera_speed_vector = @as(zm.Vec3f, @splat(camera_speed));

    const inverse_vector = @as(zm.Vec3f, @splat(-1));

    if (w_pressed) {
        camera.translate(camera.front * camera_speed_vector);
    }
    if (a_pressed) {
        const translation = zm.vec.normalize(zm.vec.cross(camera.front, zm.vec.up(f32))) * camera_speed_vector;
        camera.translate(translation * inverse_vector);
    }
    if (s_pressed) {
        camera.translate(camera.front * camera_speed_vector * inverse_vector);
    }
    if (d_pressed) {
        const translation = zm.vec.normalize(zm.vec.cross(camera.front, zm.vec.up(f32))) * camera_speed_vector;
        camera.translate(translation);
    }
}

pub fn render() void {
    delta = rgfw.RGFW_getTimeNS() - start;
    delta_second = @as(f32, @floatFromInt(delta)) / 1_000_000_000;

    gl.ClearColor(0.1, 0.1, 0.1, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

    light_position[0] = 1.0 + std.math.sin(delta_second) * 2.0;
    light_position[1] = std.math.sin(delta_second / 2.0) * 1.0;

    {
        {
            const view = camera.getViewMatrix();

            for (shaders.shaders()) |shader| {
                shader.use();
                const idx = gl.GetUniformLocation(shader.program, "view");
                gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&view.data));
            }
        }

        gl.BindVertexArray(VAO);
        defer gl.BindVertexArray(0);

        {
            const model = zm.Mat4f.translationVec3(.{ 0.0, 0.0, 0.0 });

            shaders.object_shader.use();
            {
                const idx = gl.GetUniformLocation(shaders.object_shader.program, "model");
                gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&model.data));
            }
            {
                const idx = gl.GetUniformLocation(shaders.object_shader.program, "lightPos");
                gl.Uniform3fv(idx, 1, @ptrCast(&light_position));
            }
            {
                const idx = gl.GetUniformLocation(shaders.object_shader.program, "viewPos");
                gl.Uniform3fv(idx, 1, @ptrCast(&camera.position));
            }
            gl.DrawElements(gl.TRIANGLES, 6 * 6, gl.UNSIGNED_INT, 0);
        }

        {
            shaders.light_shader.use();
            const model = zm.Mat4f.translationVec3(light_position)
                .multiply(zm.Mat4f.scaling(0.2, 0.2, 0.2));
            const idx = gl.GetUniformLocation(shaders.light_shader.program, "model");
            gl.UniformMatrix4fv(idx, 1, gl.TRUE, @ptrCast(&model.data));
            gl.DrawElements(gl.TRIANGLES, 6 * 6, gl.UNSIGNED_INT, 0);
        }
    }
}
