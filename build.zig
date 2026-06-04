const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addModule("zsx", .{
        .root_source_file = b.path("lang/zsx.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "zsx-compile",
        .root_module = b.createModule(.{
            .root_source_file = b.path("lang/compiler.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run zsx-compile");
    run_step.dependOn(&run_cmd.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/all.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zsx", .module = lib },
            },
        }),
    });
    const run_tests = b.addRunArtifact(tests);
    run_tests.has_side_effects = true;
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}

pub fn addTemplates(
    b: *std.Build,
    zsx_dep: *std.Build.Dependency,
    template_paths: []const std.Build.LazyPath,
) *std.Build.Step {
    const zsx_exe = zsx_dep.artifact("zsx-compile");
    const usf = b.addUpdateSourceFiles();

    for (template_paths) |template_path| {
        const run = b.addRunArtifact(zsx_exe);
        run.addFileArg(template_path);
        run.addFileInput(template_path);
        const basename = getBasename(template_path);
        const output = run.addOutputFileArg(replaceExtension(b, basename, ".zig"));
        const output_sub_path = replaceExtension(b, getSubPath(template_path), ".zig");
        usf.addCopyFileToSource(output, output_sub_path);
    }

    return &usf.step;
}

fn getSubPath(path: std.Build.LazyPath) []const u8 {
    return switch (path) {
        .src_path => |p| p.sub_path,
        else => @panic("unsupported path type"),
    };
}

fn getBasename(path: std.Build.LazyPath) []const u8 {
    return std.fs.path.basename(getSubPath(path));
}

fn replaceExtension(b: *std.Build, path: []const u8, new_ext: []const u8) []const u8 {
    const stem = path[0 .. path.len - std.fs.path.extension(path).len];
    return std.mem.concat(b.allocator, u8, &.{ stem, new_ext }) catch @panic("OOM");
}
