const app_config: App.Config = .{
    .address = options.host,
    .port = options.port,
};

pub fn main() !void {
    var gpa: heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const path = path: {
        var args = try process.argsWithAllocator(allocator);
        defer args.deinit();

        // skip exe name
        _ = args.next();

        const path_arg = args.next() orelse return error.MissingArgs;
        if ((try fs.cwd().statFile(path_arg)).kind != .directory) return error.NotADirectory;

        break :path try allocator.dupe(u8, path_arg);
    };
    defer allocator.free(path);

    log.info("Serve from {s}", .{path});

    var server: App.Server = try .init(allocator, app_config, &.{ .path = path });
    defer server.deinit();

    log.info("http://{s}:{d}", .{
        server.config.address.?,
        server.config.port.?,
    });
    try server.listen();
}

const App = @import("serve_lib");
const fs = std.fs;
const heap = std.heap;
const log = std.log.scoped(.serve);
const options = @import("options");
const process = std.process;
const std = @import("std");
