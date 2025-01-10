const std = @import("std");
const rgfw = @import("rgfw.zig").rgfw;
const gl = @import("gl");
const render = @import("render.zig");

var procs: gl.ProcTable = undefined;

pub fn main() !void {
    const window = rgfw.RGFW_createWindow("FooBar", rgfw.RGFW_RECT(0, 0, 800, 600), rgfw.RGFW_CENTER | rgfw.RGFW_NO_RESIZE);
    rgfw.RGFW_window_makeCurrent(window);

    if (!procs.init(rgfw.RGFW_getProcAddress)) return error.InitFailed;
    gl.makeProcTableCurrent(&procs);
    defer gl.makeProcTableCurrent(null);

    const result = gl.GetString(gl.VERSION) orelse unreachable;
    std.debug.print("OpenGL version: {s}\n", .{result});

    render.init();

    while (rgfw.RGFW_window_shouldClose(window) == rgfw.RGFW_FALSE) {
        while (rgfw.RGFW_window_checkEvent(window) != null) {
            if (window.*.event.type == rgfw.RGFW_quit) {
                rgfw.RGFW_window_setShouldClose(window);
            }
        }

        render.render();

        rgfw.RGFW_window_swapBuffers(window);
    }
    rgfw.RGFW_window_close(window);
}
