const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "graphics-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    addRGFW(b, exe, target);
    addOpenGL(b, exe);
    addZm(b, exe);
    addFreeType(b, exe, target, optimize);
    addHarfBuzz(b, exe, target, optimize);
    addFontAssets(b, exe);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    addRGFW(b, exe_unit_tests, target);
    addOpenGL(b, exe_unit_tests);
    addZm(b, exe_unit_tests);
    addFreeType(b, exe_unit_tests, target, optimize);
    addHarfBuzz(b, exe_unit_tests, target, optimize);
    addFontAssets(b, exe_unit_tests);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn addRGFW(b: *std.Build, compile: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    compile.linkLibC();
    compile.addIncludePath(b.path("vendor/rgfw"));
    compile.addCSourceFile(.{
        .file = b.path("src/rgfw.c"),
    });

    if (target.result.os.tag == .windows) {
        compile.linkSystemLibrary("gdi32");
        compile.linkSystemLibrary("shell32");
        compile.linkSystemLibrary("opengl32");
        compile.linkSystemLibrary("winmm");
        compile.linkSystemLibrary("user32");
    } else if (target.result.os.tag == .linux) {
        compile.linkSystemLibrary("X11");
        compile.linkSystemLibrary("Xcursor");
        compile.linkSystemLibrary("GL");
    } else if (target.result.os.tag == .macos) {
        compile.linkFramework("Cocoa");
        compile.linkFramework("OpenGL");
        compile.linkFramework("IOKit");
    } else {
        @panic("Unsupported target OS");
    }
}

fn addOpenGL(b: *std.Build, compile: *std.Build.Step.Compile) void {
    const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
        .api = .gl,
        .version = .@"4.1",
    });

    compile.root_module.addImport("gl", gl_bindings);
}

fn addZm(b: *std.Build, compile: *std.Build.Step.Compile) void {
    const zm = b.dependency("zm", .{});
    compile.root_module.addImport("zm", zm.module("zm"));
}

fn addFreeType(b: *std.Build, compile: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const mach_freetype = b.dependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    });
    compile.root_module.addImport("freetype", mach_freetype.module("mach-freetype"));
}

fn addHarfBuzz(b: *std.Build, compile: *std.Build.Step.Compile, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) void {
    const mach_freetype = b.dependency("mach_freetype", .{
        .target = target,
        .optimize = optimize,
    });
    compile.root_module.addImport("harfbuzz", mach_freetype.module("mach-harfbuzz"));
}

fn addFontAssets(b: *std.Build, compile: *std.Build.Step.Compile) void {
    const font_assets = b.dependency("font_assets", .{});
    compile.root_module.addImport("font-assets", font_assets.module("font-assets"));
}
