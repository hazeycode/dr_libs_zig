const std = @import("std");

pub fn module(b: *std.Build) *std.Build.Module {
    return b.createModule(.{
        .source_file = .{ .path = thisDir() ++ "/src/main.zig" },
    });
}

pub fn staticLibrary(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) *std.Build.CompileStep {
    const lib = b.addStaticLibrary(.{
        .name = "dr_libs_zig",
        .target = target,
        .optimize = optimize,
    });
    lib.addCSourceFile(thisDir() ++ "/src/dr_libs.c", &.{
        "-std=c99",
        "-fno-sanitize=undefined",
    });
    lib.linkLibC();
    return lib;
}

pub fn tests(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.Mode,
) *std.Build.CompileStep {
    const all_tests = b.addTest(.{
        .name = "tests",
        .root_source_file = .{ .path = thisDir() ++ "/src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    all_tests.linkLibrary(staticLibrary(b, target, optimize));
    return all_tests;
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&tests(b, target, optimize).step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
