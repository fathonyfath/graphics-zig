const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("module", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    addRGFW(b, module, target);
    addOpenGL(b, module);
    addStbImage(b, module);
    addZm(b, module);

    const exe = b.addExecutable(.{
        .name = "graphics-zig",
        .root_module = module,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_module = module,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn addRGFW(b: *std.Build, module: *std.Build.Module, target: std.Build.ResolvedTarget) void {
    module.link_libc = true;
    module.addIncludePath(b.path("vendor/rgfw"));
    module.addCSourceFile(.{
        .file = b.path("src/rgfw.c"),
    });

    if (target.result.os.tag == .windows) {
        module.linkSystemLibrary("gdi32", .{});
        module.linkSystemLibrary("shell32", .{});
        module.linkSystemLibrary("opengl32", .{});
        module.linkSystemLibrary("winmm", .{});
        module.linkSystemLibrary("user32", .{});
    } else if (target.result.os.tag == .linux) {
        module.linkSystemLibrary("X11", .{});
        module.linkSystemLibrary("Xcursor", .{});
        module.linkSystemLibrary("GL", .{});
    } else if (target.result.os.tag == .macos) {
        module.linkFramework("Cocoa", .{});
        module.linkFramework("OpenGL", .{});
        module.linkFramework("IOKit", .{});
    } else {
        @panic("Unsupported target OS");
    }
}

fn addOpenGL(b: *std.Build, module: *std.Build.Module) void {
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
    });

    module.addImport("gl", gl_bindings);
}

fn addStbImage(b: *std.Build, module: *std.Build.Module) void {
    module.link_libc = true;
    module.addIncludePath(b.path("vendor/stb"));
    module.addCSourceFile(.{
        .file = b.path("src/stb_image.c"),
    });
}

fn addZm(b: *std.Build, module: *std.Build.Module) void {
    const zm = b.dependency("zm", .{});
    module.addImport("zm", zm.module("zm"));
}
