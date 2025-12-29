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

        const bytes_read = Request.read_request(io, connection, request_buffer[0..]) catch |err| {
            if (err == error.EndOfStream) {
                print("Client disconnected\n", .{});
                continue;
            }
            return err;
        };

        const request = try Request.parse_request(request_buffer[0..bytes_read]);

        // Debug printing for learning.
        print("method: {},\nuri: {s}, \nversion: {s}, \n", .{ request.method, request.uri, request.version });
        print("Host: {s}\n", .{request.headers.get("host") orelse "none"});
        print("Content-Type: {s}\n", .{request.headers.get("content-type") orelse "none"});
        print("Content-Length: {s}\n", .{request.headers.get("content-length") orelse "0"});
        print("User-Agent: {s}\n", .{request.headers.get("user-agent") orelse "none"});

        switch (request.method) {
            .GET => {
                if (std.mem.eql(u8, request.uri, "/")) {
                    try Response.send_200(connection, io);
                } else {
                    try Response.send_404(connection, io);
                }
            },
            .POST => {
                print("POST body: {s}\n", .{request.body});
                try Response.send_200(connection, io);
            },
        }
    }
}
