# Zig HTTP Server

  A minimal HTTP/1.1 server built from scratch in Zig as a learning project.

  ## Features

  - GET and POST request handling
  - Header parsing
  - Body parsing with Content-Length
  - Basic routing

  ## Usage

  ```bash
  zig build run
```

Then visit http://localhost:8080/ or:

  curl http://localhost:8080/
  curl -X POST -d "hello" http://localhost:8080/
