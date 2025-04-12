path: []const u8,

pub const Server = httpz.Server(*const App);
pub const Config = httpz.Config;

pub fn handle(self: *const App, req: *httpz.Request, res: *httpz.Response) void {
    switch (req.method) {
        .GET => {},
        .HEAD => {
            res.status = 501;
            res.body = "Not implemented";
            return;
        },
        else => {
            res.status = 405;
            res.body = "Method not allowed";
            return;
        },
    }

    // Prevent malicious requests like GET //etc/hosts
    if (mem.containsAtLeast(u8, req.url.path, 1, "//")) {
        res.status = 400;
        res.body = "Bad request";
        return;
    }

    var dir = fs.cwd().openDir(self.path, .{}) catch {
        res.status = 500;
        res.body = "Internal server error";
        return;
    };
    defer dir.close();

    const sub_path = filePath(req);
    serveFile(&dir, sub_path, res) catch |err| {
        if (options.additional_redirect and err == error.IsDir) {
            const path = fmt.allocPrint(req.arena, "{s}/", .{req.url.path}) catch {
                res.status = 500;
                res.body = "Internal server error";
                return;
            };
            res.status = 302;
            res.header("Location", path);
            return;
        }

        std.log.info("error: {any}", .{err});
        res.status = 404;
        res.body = "Not found";
        return;
    };
}

fn filePath(req: *httpz.Request) FilePath {
    std.log.info("{s}", .{req.url.path});
    if (mem.eql(u8, req.url.path, "/")) {
        return .{ .file = "index.html" };
    }

    if (mem.endsWith(u8, req.url.path, "/")) {
        return .{ .directory = req.url.path[1..] };
    }

    return .{ .file = req.url.path[1..] };
}

fn serveFile(dir: *fs.Dir, sub_path: FilePath, res: *httpz.Response) !void {
    switch (sub_path) {
        .directory => |path| {
            var sub_dir = try dir.openDir(path, .{});
            defer sub_dir.close();
            var file = try sub_dir.openFile("index.html", .{});
            defer file.close();

            var fifo: std.fifo.LinearFifo(u8, .{ .Static = 1024 }) = .init();
            try fifo.pump(file.reader(), res.writer());

            res.header("Content-Type", Mime.html.contentType());
        },
        .file => |path| {
            var file = try dir.openFile(path, .{});
            defer file.close();

            var fifo: std.fifo.LinearFifo(u8, .{ .Static = 1024 }) = .init();
            try fifo.pump(file.reader(), res.writer());

            if (Mime.match(path)) |mime| {
                res.header("Content-Type", mime.contentType());
            }
        },
    }
}

const Mime = enum {
    html,
    javascript,
    wasm,

    const ExtensionMap: std.EnumArray(Mime, []const []const u8) = .init(.{
        .html = &.{".html"},
        .javascript = &.{".js"},
        .wasm = &.{ ".wasm.a", ".wasm" },
    });

    pub fn match(file_name: []const u8) ?Mime {
        inline for (@typeInfo(Mime).@"enum".fields) |f| {
            const key = @field(Mime, f.name);
            for (ExtensionMap.get(key)) |ext| {
                if (mem.endsWith(u8, file_name, ext)) {
                    return key;
                }
            }
        }

        return null;
    }

    pub fn contentType(mime: Mime) []const u8 {
        return switch (mime) {
            .html => "text/html",
            .javascript => "text/javascript",
            .wasm => "application/wasm",
        };
    }
};

const FilePath = union(enum) {
    file: []const u8,
    directory: []const u8,
};

const App = @This();
const fmt = std.fmt;
const fs = std.fs;
const httpz = @import("httpz");
const mem = std.mem;
const options = @import("options");
const std = @import("std");
