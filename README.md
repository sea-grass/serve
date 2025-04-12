# Serve

Serve is a small command-line utility to serve files via localhost.

## Features

- Local HTTP server (always `http://127.0.0.1:3000`)
- Specified directory path (as a command line argument)
- File server (all files from within this directory path)
- Request path mapping (e.g. `GET /app.js` -> `app.js`)
- Index file mapping (e.g. `GET /some-path/` maps to the file `some-path/index.html`)
- File extension-based content-type header

## Supported Zig version

Serve is tested with Zig `0.14.0`. Your mileage may vary on other versions. If you encounter an issue, patches are encouraged.

## Usage

At the moment, there are no published binaries. If you want to use Serve, you'll need to obtain a copy of the Zig compiler and build it yourself.

To build the project, simply clone the repository, enter the directory, then build the project with:

```
zig build
```

The program will be available in your current directory at `zig-out/bin/serve`. Feel free to copy this somewhere accessible via your `PATH`.

Alternatively, you can build an optimized executable by building in release mode:

```
# build in release mode
zig build -Doptimize=ReleaseSafe
# or, build a release binary optimized for size
zig build -Doptimize=ReleaseSmall
```

## Alternatives

Serve is meant to be used as a local development tool to serve files via localhost only. If you are looking for a static server to run on your production system, this is not it. For production, consider something like nginx.

An alternative you could consider is the [Python 3 built-in module `http.server`](https://docs.python.org/3/library/http.server.html).

## Contributions

Patches are welcome.

## Acknowledgements

- [Zig](https://ziglang.org/) - This project is written in Zig
- [http.zig](https://github.com/karlseguin/http.zig) - This project is a thin wrapper around http.zig
