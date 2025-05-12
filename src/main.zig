// See LICENSE file for copyright and license details.
const std = @import("std");
const posix = std.posix;
const Server = @import("wayland.zig").Server;
const gpa = std.heap.c_allocator;

pub fn main() anyerror!void {
    var server: Server = undefined;
    try server.init();
    defer server.deinit();

    var buf: [11]u8 = undefined;
    const socket = try server.wl_server.addSocketAuto(&buf);

    if (std.os.argv.len >= 2) {
        const cmd = std.mem.span(std.os.argv[1]);
        var child = std.process.Child.init(&[_][]const u8{ "/bin/sh", "-c", cmd }, gpa);
        var env_map = try std.process.getEnvMap(gpa);
        defer env_map.deinit();
        try env_map.put("WAYLAND_DISPLAY", socket);
        child.env_map = &env_map;
        try child.spawn();
    }

    try server.backend.start();

    std.log.info("Running compositor on WAYLAND_DISPLAY={s}", .{socket});
    server.wl_server.run();
}
