const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core_module = b.addModule("auk", .{
        .root_source_file = b.path("core/root.zig"),
    });

    const auk = b.addExecutable(.{
        .name = "auk",
        .root_source_file = b.path("auk.zig"),
        .target = target,
        .optimize = optimize,
    });
    auk.root_module.addImport("auk", core_module);
    b.installArtifact(auk);

    const run_auk = b.addRunArtifact(auk);
    run_auk.step.dependOn(b.getInstallStep());

    const run_auk_step = b.step("run", "Run auk");
    run_auk_step.dependOn(&run_auk.step);

    const auk_test = b.addTest(.{
        .root_source_file = b.path("auk.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_auk_test = b.addRunArtifact(auk_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_auk_test.step);
}
