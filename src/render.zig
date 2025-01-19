const std = @import("std");
const gl = @import("gl");
const Shader = @import("Shader.zig");
const fonts = @import("fonts.zig");
const zm = @import("zm");

pub fn init() void {
    fonts.init();
}

pub fn render() void {
    gl.ClearColor(0.2, 0.3, 0.3, 1.0);
    gl.Clear(gl.COLOR_BUFFER_BIT);

    fonts.renderText("This is sample text", 25.0, 25.0, 1.0, .{ 0.5, 0.8, 0.2 });
    fonts.renderText("(C) LearnOpenGL.com", 540.0, 570.0, 0.5, .{ 0.3, 0.7, 0.9 });
}
