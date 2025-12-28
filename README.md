# Zig HTTP Server

A minimal HTTP/1.1 server built from scratch in Zig.

## Why?

I built this to learn two things at once:

1. **Zig patterns** — error propagation with `try`, optionals with `orelse`, `defer` for cleanup, comptime string maps, slice manipulation, and how structs with methods replace classes
2. **HTTP internals** — what actually happens when bytes arrive on a socket, how `\r\n` delimiters separate headers, how `Content-Length` tells you when the body ends, and the request/response cycle at the protocol level

No frameworks, no shortcuts — just `std.Io.net` sockets and byte parsing.

## Features

- GET and POST request handling
- Header parsing (iterating raw bytes to find `: ` delimiters)
- Body parsing with Content-Length
- Basic routing

## Usage

```bash
zig build run
```

Then visit `http://localhost:8080/` or use curl:

```bash
curl http://localhost:8080/
curl -X POST -d "hello" http://localhost:8080/
```
