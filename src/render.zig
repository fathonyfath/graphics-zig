const std = @import("std");
const gl = @import("gl");
const Shader = @import("Shader.zig");

const vertex_shader_source =
    \\#version 330 core
    \\layout(location = 0) in vec3 aPos;
    \\
    \\void main() {
    \\  gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    \\}
    \\
;

const fragment_shader_source =
    \\#version 330 core
    \\out vec4 FragColor;
    \\
    \\void main() {
    \\  FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    \\}
    \\
;

const vertices_triangle = [_]f32{
    -0.5, -0.5, 0.0,
    0.5,  -0.5, 0.0,
    0.0,  0.5,  0.0,
};

const indices_triangle = [_]u32{
    0, 1, 2,
};

const vertices_square = [_]f32{
    0.5,  0.5,  0.0,
    0.5,  -0.5, 0.0,
    -0.5, -0.5, 0.0,
    -0.5, 0.5,  0.0,
};

const indices_square = [_]u32{
    0, 1, 3,
    1, 2, 3,
};

var VAO: gl.uint = undefined;
var VBO: gl.uint = undefined;
var EBO: gl.uint = undefined;

var shader: Shader = undefined;

pub fn init() void {
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
            gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), 0);
        }
    }

    shader = Shader.create(vertex_shader_source, fragment_shader_source);
}

var draw_square: bool = true;

pub fn render() void {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    draw_square = !draw_square;

    shader.use();

    {
        if (draw_square) {
            {
                gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
                defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

                gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices_square)), &vertices_square, gl.STATIC_DRAW);
            }
            {
                gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
                defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

                gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices_square)), &indices_square, gl.STATIC_DRAW);
            }
        } else {
            {
                gl.BindBuffer(gl.ARRAY_BUFFER, VBO);
                defer gl.BindBuffer(gl.ARRAY_BUFFER, 0);

                gl.BufferData(gl.ARRAY_BUFFER, @sizeOf(@TypeOf(vertices_triangle)), &vertices_triangle, gl.STATIC_DRAW);
            }
            {
                gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);
                defer gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, 0);

                gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, @sizeOf(@TypeOf(indices_triangle)), &indices_triangle, gl.STATIC_DRAW);
            }
        }
    }

    {
        gl.BindVertexArray(VAO);
        defer gl.BindVertexArray(0);

        gl.DrawElements(gl.TRIANGLES, if (draw_square) 6 else 3, gl.UNSIGNED_INT, 0);
    }
}
