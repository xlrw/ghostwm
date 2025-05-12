// See LICENSE file for copyright and license details.
const std = @import("std");
const Scanner = @import("wayland").Scanner;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const scanner = Scanner.create(b, .{});
    scanner.addSystemProtocol("stable/xdg-shell/xdg-shell.xml");
    scanner.addSystemProtocol("stable/tablet/tablet-v2.xml");

    scanner.generate("wl_compositor", 4);
    scanner.generate("wl_subcompositor", 1);
    scanner.generate("wl_shm", 1);
    scanner.generate("wl_output", 4);
    scanner.generate("wl_seat", 7);
    scanner.generate("wl_data_device_manager", 3);
    scanner.generate("xdg_wm_base", 2);
    scanner.generate("zwp_tablet_manager_v2", 1);

    const wayland = b.createModule(.{ .root_source_file = scanner.result });
    const xkbcommon = b.dependency("xkbcommon", .{}).module("xkbcommon");
    const pixman = b.dependency("pixman", .{}).module("pixman");
    const wlroots = b.dependency("wlroots", .{}).module("wlroots");

    wlroots.addImport("wayland", wayland);
    wlroots.addImport("xkbcommon", xkbcommon);
    wlroots.addImport("pixman", pixman);

    wlroots.resolved_target = target;
    wlroots.linkSystemLibrary("wlroots-0.18", .{});

    const ghostwm = b.addExecutable(.{
        .root_source_file = b.path("src/main.zig"),
        .name = "ghostwm",
        .target = target,
        .optimize = optimize,
    });

    ghostwm.linkLibC();

    ghostwm.root_module.addImport("wayland", wayland);
    ghostwm.root_module.addImport("xkbcommon", xkbcommon);
    ghostwm.root_module.addImport("wlroots", wlroots);

    ghostwm.linkSystemLibrary("wayland-server");
    ghostwm.linkSystemLibrary("xkbcommon");
    ghostwm.linkSystemLibrary("pixman-1");

    b.installArtifact(ghostwm);

    const run_cmd = b.addRunArtifact(ghostwm);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
