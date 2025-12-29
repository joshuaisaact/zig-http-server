const std = @import("std");
const Stream = std.Io.net.Stream;

pub fn read_request(io: std.Io, conn: Stream, buffer: []u8) !usize {
    var recv_buffer: [1024]u8 = undefined;
    var reader = conn.reader(io, &recv_buffer);
    const reader_interface = &reader.interface;
    var start_index: usize = 0;

    while (true) {
        const len = try read_next_line(reader_interface, buffer, start_index);
        start_index += len;

        if (len <= 2) break; // End of headers (blank line)
    }

    const content_length = parse_content_length(buffer[0..start_index]) orelse 0;

    if (content_length > 0) {
        try reader_interface.readSliceAll(buffer[start_index..(start_index + content_length)]);
        start_index += content_length;
    }

    return start_index;
}

fn read_next_line(reader: *std.Io.Reader, buffer: []u8, start_index: usize) !usize {
    const next_line = try reader.takeDelimiterInclusive('\n');
    @memcpy(buffer[start_index..(start_index + next_line.len)], next_line[0..]);
    return next_line.len;
}

const Map = std.static_string_map.StaticStringMap;
const MethodMap = Map(Method).initComptime(.{
    .{ "GET", Method.GET },
    .{ "POST", Method.POST },
});

pub const Method = enum {
    GET,
    POST,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }

    pub fn is_supported(m: []const u8) bool {
        const method = MethodMap.get(m);
        if (method) |_| {
            return true;
        }
        return false;
    }
};

const Headers = struct {
    keys: [32][]const u8 = undefined,
    values: [32][]const u8 = undefined,
    len: usize = 0,

    pub fn add(self: *Headers, key: []const u8, value: []const u8) !void {
        if (self.len >= 32) return error.TooManyHeaders;
        self.keys[self.len] = key;
        self.values[self.len] = value;
        self.len += 1;
    }

    pub fn get(self: Headers, needle: []const u8) ?[]const u8 {
        for (self.keys[0..self.len], self.values[0..self.len]) |key, value| {
            if (std.mem.eql(u8, key, needle)) return value;
        }
        return null;
    }

    pub fn reset(self: *Headers) void {
        self.len = 0;
    }
};

const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,
    headers: Headers,
    content_length: usize,
    body: []const u8,

    pub fn init(method: Method, uri: []const u8, version: []const u8, headers: Headers, content_length: usize, body: []const u8) Request {
        return Request{
            .method = method,
            .uri = uri,
            .version = version,
            .headers = headers,
            .content_length = content_length,
            .body = body,
        };
    }
};

fn parseHeaders(raw: []const u8, headers: *Headers) !void {
    var lines = std.mem.splitSequence(u8, raw, "\r\n");

    while (lines.next()) |line| {
        if (line.len == 0) break;

        const colon = std.mem.indexOf(u8, line, ":") orelse continue;
        const key = line[0..colon];

        var value_start = colon + 1;
        if (value_start < line.len and line[value_start] == ' ') {
            value_start += 1;
        }
        const value = line[value_start..];

        try headers.add(key, value);
    }
}

pub fn parse_request(text: []u8) !Request {
    const line_index = std.mem.findScalar(u8, text, '\n') orelse text.len;
    const line_end = if (line_index > 0 and text[line_index - 1] == '\r') line_index - 1 else line_index;

    var iterator = std.mem.splitScalar(u8, text[0..line_end], ' ');
    const method = Method.init(iterator.next().?) catch Method.GET;
    const uri = iterator.next().?;
    const version = iterator.next().?;
    var headers = Headers{};
    const header_text = text[(line_index + 1)..];
    try parseHeaders(header_text, &headers);
    const cl_str = headers.get("Content-Length") orelse "";
    const content_length = atoi(cl_str) orelse 0;
    const body = parse_body(text, content_length);

    const request = Request.init(method, uri, version, headers, content_length, body);
    return request;
}

fn parse_content_length(headers: []const u8) ?usize {
    const needle = "Content-Length: ";
    const start = std.mem.indexOf(u8, headers, needle) orelse return null;
    const value_start = start + needle.len;

    const value_end = std.mem.indexOfScalarPos(u8, headers, value_start, '\r') orelse std.mem.indexOfScalarPos(u8, headers, value_start, '\n') orelse headers.len;

    return std.fmt.parseInt(usize, headers[value_start..value_end], 10) catch null;
}

fn parse_body(text: []const u8, content_length: usize) []const u8 {
    const separator = "\r\n\r\n";
    const body_start = std.mem.indexOf(u8, text, separator) orelse return "";
    const actual_start = body_start + separator.len;

    if (actual_start >= text.len) return "";

    const end = @min(actual_start + content_length, text.len);
    return text[actual_start..end];
}

fn atoi(str: []const u8) ?usize {
    if (str.len == 0) return null;

    var n: usize = 0;
    for (str) |byte| {
        // Only accept ASCII digits
        if (byte < '0' or byte > '9') return null;

        // Multiply by 10, checking for overflow
        n = std.math.mul(usize, n, 10) catch return null;

        // Add the digit, checking for overflow
        n = std.math.add(usize, n, @intCast(byte - '0')) catch return null;
    }
    return n;
}
