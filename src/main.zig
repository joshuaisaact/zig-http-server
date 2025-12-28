const std = @import("std");
const print = std.debug.print;
const Request = @import("request.zig");
const Response = @import("response.zig");
const Server = @import("server.zig").Server;

pub fn main() !void {
    var alloc = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = alloc.allocator();
    var threaded: std.Io.Threaded = .init(gpa);
    const io = threaded.io();
    defer threaded.deinit();

    const server = try Server.init(io);
    var listening = try server.listen();

    while (true) {
        const connection = try listening.accept(io);
        defer connection.close(io);

        var request_buffer: [1000]u8 = undefined;
        @memset(request_buffer[0..], 0);
        try Request.read_request(io, connection, request_buffer[0..]);

        const request = Request.parse_request(request_buffer[0..]);
        print("method: {},\nuri: {s}, \nversion: {s}, \nheader: {s}\n", .{ request.method, request.uri, request.version, request.header });
        if (request.method == Request.Method.GET) {
            if (std.mem.eql(u8, request.uri, "/")) {
                try Response.send_200(connection, io);
            } else {
                try Response.send_404(connection, io);
            }
        }
    }
}
