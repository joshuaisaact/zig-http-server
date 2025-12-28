const std = @import("std");
const print = std.debug.print;
const Socket = std.Io.net.Socket;
const Protocol = std.Io.net.Protocol;

pub const Server = struct {
    host: []const u8,
    port: u16,
    addr: std.Io.net.IpAddress,
    io: std.Io,

    pub fn init(io: std.Io) !Server {
        const host: []const u8 = "127.0.0.1";
        const port: u16 = 3490;
        const address = try std.Io.net.IpAddress.parseIp4(host, port);

        return .{ .host = host, .port = port, .addr = address, .io = io };
    }

    pub fn listen(self: Server) !std.Io.net.Server {
        print("Server Addr: {s}:{any}\n", .{ self.host, self.port });
        return try self.addr.listen(self.io, .{ .mode = Socket.Mode.stream, .protocol = Protocol.tcp, .reuse_address = true });
    }
};
