const std = @import("std");
const builtin = @import("builtin");

const Version = std.SemanticVersion;

const Manifest = struct {
    const ZON = struct { version: []const u8 };

    version: Version,

    fn parse(allocator: std.mem.Allocator, source: [:0]const u8) !Manifest {
        const zon = try std.zon.parse.fromSlice(
            ZON,
            allocator,
            source,
            null,
            .{ .ignore_unknown_fields = true },
        );
        return .{ .version = try Version.parse(zon.version) };
    }
};

pub fn build(b: *std.Build) !void {
    const manifest = try Manifest.parse(b.allocator, @embedFile("build.zig.zon"));

    const manifest_options = b.addOptions();
    manifest_options.addOption(Version, "version", manifest.version);

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const core_module = b.addModule("auk", .{
        .root_source_file = b.path("core/root.zig"),
    });
    core_module.addOptions("manifest", manifest_options);

    const terminal_module = b.addModule("auk", .{
        .root_source_file = b.path("terminal/root.zig"),
    });

    const auk = b.addExecutable(.{
        .name = "auk",
        .root_source_file = b.path("auk.zig"),
        .target = target,
        .optimize = optimize,
    });
    auk.root_module.addImport("auk", core_module);
    auk.root_module.addImport("auk.terminal", terminal_module);
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
    auk_test.root_module.addImport("auk", core_module);
    const run_auk_test = b.addRunArtifact(auk_test);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_auk_test.step);
}
