path: []const u8,

pub const Server = httpz.Server(*const App);
pub const Config = httpz.Config;

pub fn handle(self: *const App, req: *httpz.Request, res: *httpz.Response) void {
    // Prevent malicious requests like GET //etc/hosts
    if (mem.containsAtLeast(u8, req.url.path, 1, "//")) {
        res.status = 400;
        res.body = "Bad request";
        return;
    }

    const sub_path = filePath(req);
    var dir = fs.cwd().openDir(self.path, .{}) catch {
        res.status = 500;
        res.body = "Internal server error";
        return;
    };
    defer dir.close();

    serveFile(&dir, sub_path, res) catch {
        res.status = 404;
        res.body = "Not found";
        return;
    };
}

fn filePath(req: *httpz.Request) []const u8 {
    std.log.info("{s}", .{req.url.path});
    if (mem.eql(u8, req.url.path, "/")) {
        return "index.html";
    }

    if (mem.endsWith(u8, req.url.path, "/")) {
        return std.fmt.allocPrint(req.arena, "{s}index.html", .{req.url.path[1..]}) catch @panic("Could not allocate enough memory to satisfy this request.");
    }

    return req.url.path[1..];
}

fn serveFile(dir: *fs.Dir, sub_path: []const u8, res: *httpz.Response) !void {
    var file = try dir.openFile(sub_path, .{});
    defer file.close();

    var fifo: std.fifo.LinearFifo(u8, .{ .Static = 1024 }) = .init();
    try fifo.pump(file.reader(), res.writer());

    if (Mime.match(sub_path)) |mime| {
        res.header("Content-Type", mime.contentType());
    }
}

const Mime = enum {
    wasm,
    javascript,

    const ExtensionMap: std.EnumArray(Mime, []const []const u8) = .init(.{
        .wasm = &.{ ".wasm.a", ".wasm" },
        .javascript = &.{".js"},
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
            .wasm => "application/wasm",
            .javascript => "text/javascript",
        };
    }
};

const App = @This();
const fs = std.fs;
const httpz = @import("httpz");
const mem = std.mem;
const std = @import("std");
