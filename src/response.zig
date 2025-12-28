const std = @import("std");
const Stream = std.Io.net.Stream;

pub fn send_200(conn: Stream, io: std.Io) !void {
    const message = "HTTP/1.1 200 OK\r\nContent-Length: 48\r\nContent-Type: text/html\r\nConnection: Closed\r\n\r\n<html><body><h1>Hello, World!</h1></body></html>";
    var stream_writer = conn.writer(io, &.{});
    _ = try stream_writer.interface.write(message);
}

pub fn send_404(conn: Stream, io: std.Io) !void {
    const message = "HTTP/1.1 404 Not Found\r\nContent-Length: 50\r\nContent-Type: text/html\r\nConnection: Closed\r\n\r\n<html><body><h1>File not found!</h1></body></html>";
    var stream_writer = conn.writer(io, &.{});
    _ = try stream_writer.interface.write(message);
}

pub fn send_405(conn: Stream, io: std.Io) !void {
    const message = ("HTTP/1.1 405 Method Not Allowed\r\nContent-Length: 0\r\nConnection: Closed\r\n\r\n");
    var stream_writer = conn.writer(io, &.{});
    _ = try stream_writer.interface.write(message);
}
