const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core_module = b.addModule("auk", .{
        .root_source_file = b.path("core/root.zig"),
        .imports = &.{
            .{
                .name = "auk.manifest",
                .module = b.createModule(.{
                    .root_source_file = b.path("manifest.zig"),
                }),
            },
        },
    });

    const terminal_module = b.addModule("auk.terminal", .{
        .root_source_file = b.path("terminal/root.zig"),
    });

    const evtmon_module = b.createModule(.{
        .root_source_file = b.path("auk.zig"),
        .imports = &.{
            .{
                .name = "auk",
                .module = core_module,
            },
            .{
                .name = "auk.terminal",
                .module = terminal_module,
            },
        },
        .target = target,
        .optimize = optimize,
    });
    const auk = b.addExecutable(.{
        .name = "auk",
        .root_module = evtmon_module,
    });
    b.installArtifact(auk);

    const run_auk = b.addRunArtifact(auk);
    run_auk.step.dependOn(b.getInstallStep());

    const run_auk_step = b.step("run", "Run auk");
    run_auk_step.dependOn(&run_auk.step);

    const auk_test = b.addTest(.{
        .root_module = evtmon_module,
    });
    auk_test.root_module.addImport("auk", core_module);
    const run_auk_test = b.addRunArtifact(auk_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_auk_test.step);
}
