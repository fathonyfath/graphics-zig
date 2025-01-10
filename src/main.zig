const std = @import("std");
const rgfw = @import("rgfw.zig").rgfw;

pub fn main() !void {
    rgfw.RGFW_setGLVersion(rgfw.RGFW_glCore, 4, 1);

    const window = rgfw.RGFW_createWindow("FooBar", rgfw.RGFW_RECT(0, 0, 800, 600), rgfw.RGFW_windowCenter | rgfw.RGFW_windowNoResize);
    rgfw.RGFW_window_makeCurrent(window);

    while (rgfw.RGFW_window_shouldClose(window) == rgfw.RGFW_FALSE) {
        while (rgfw.RGFW_window_checkEvent(window) != null) {
            if (window.*.event.type == rgfw.RGFW_quit) {
                rgfw.RGFW_window_setShouldClose(window);
            }
        }

        rgfw.RGFW_window_swapBuffers(window);
    }
    rgfw.RGFW_window_close(window);
}
