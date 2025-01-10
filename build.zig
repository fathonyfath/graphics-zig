const std = @import("std");
const zigglgen = @import("zigglgen");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "graphics-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    addRGFW(b, exe);

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
    addRGFW(b, exe_unit_tests);

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}

fn addRGFW(b: *std.Build, compile: *std.Build.Step.Compile) void {
    compile.linkLibC();
    compile.addIncludePath(b.path("vendor/rgfw"));
    compile.addCSourceFile(.{
        .file = b.path("src/rgfw.c"),
    });
    compile.linkSystemLibrary("gdi32");
    compile.linkSystemLibrary("shell32");
    compile.linkSystemLibrary("opengl32");
    compile.linkSystemLibrary("winmm");
    compile.linkSystemLibrary("user32");
}
