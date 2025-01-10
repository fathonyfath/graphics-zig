const std = @import("std");
const gl = @import("gl");

program: gl.uint,

const Shader = @This();

pub fn create(
    vertex_shader_source: []const u8,
    fragment_shader_source: []const u8,
) Shader {
    const vertex_shader = compileShader(gl.VERTEX_SHADER, vertex_shader_source);
    defer gl.DeleteShader(vertex_shader);
    const fragment_shader = compileShader(gl.FRAGMENT_SHADER, fragment_shader_source);
    defer gl.DeleteShader(fragment_shader);

    const shader_program = gl.CreateProgram();
    gl.AttachShader(shader_program, vertex_shader);
    gl.AttachShader(shader_program, fragment_shader);

    gl.LinkProgram(shader_program);

    var success: gl.uint = undefined;
    gl.GetProgramiv(shader_program, gl.LINK_STATUS, @ptrCast(&success));
    if (success == gl.FALSE) {
        var info_log: [512]u8 = std.mem.zeroes([512]u8);
        gl.GetProgramInfoLog(shader_program, 512, null, @ptrCast(&info_log));
        std.debug.print("Shader link program error: {s}\n", .{info_log});
        unreachable;
    }

    return .{ .program = shader_program };
}

pub fn use(shader: Shader) void {
    gl.UseProgram(shader.program);
}

fn compileShader(@"type": gl.@"enum", shader_source: []const u8) gl.uint {
    const shader = gl.CreateShader(@"type");
    gl.ShaderSource(shader, 1, @ptrCast(&shader_source.ptr), @ptrCast(&shader_source.len));
    gl.CompileShader(shader);

    var success: gl.uint = undefined;
    gl.GetShaderiv(shader, gl.COMPILE_STATUS, @ptrCast(&success));

    if (success == gl.FALSE) {
        var info_log: [512]u8 = std.mem.zeroes([512]u8);
        gl.GetShaderInfoLog(shader, 512, null, @ptrCast(&info_log));
        std.debug.print("Shader compile error: {s}\n", .{info_log});
        unreachable;
    }

    return shader;
}
