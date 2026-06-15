# Compression Backends

XLSX files are ZIP archives of XML files. In this project the compression path
is owned by libxlsxwriter and its minizip/zlib integration.

## Current Path

The vendored libxlsxwriter makefile links with `-lz`. Unless
`USE_SYSTEM_MINIZIP` is set, libxlsxwriter builds the vendored minizip sources
and still links them against zlib.

The CMake build also requires zlib through `find_package(ZLIB "1.0" REQUIRED)`.

Use this benchmark to capture the active native library and compression metrics:

```sh
direnv exec . bundle exec ruby benchmarks/compression_backend.rb
```

The report includes:

- the `libxlsxwriter` path selected by the Ruby/FFI loader,
- linked-library output from `ldd` on Linux or `otool -L` on macOS,
- Trade Tariff-shaped workbook time,
- output bytes,
- ZIP compressed and uncompressed byte totals,
- allocation and RSS deltas where available,
- Ruby/platform metadata.

On the local Nix/glibc development shell, `libxlsxwriter.so` links to
`libz.so.1`.

## Candidate Backends

`zlib-ng` is the most plausible first candidate because it can be built in a
zlib-compatible mode. Evaluate it by building libxlsxwriter in an environment
where `-lz` resolves to the zlib-ng compatibility library, then compare
`benchmarks/compression_backend.rb` output against the default zlib build.

`libdeflate` is not a drop-in zlib replacement for this path. Testing it would
require deeper minizip/libxlsxwriter integration work, so it should not become a
default dependency without a dedicated prototype and cross-platform packaging
validation.

## Decision Rule

Keep zlib as the default until an alternative shows a clear end-to-end win on
Trade Tariff-shaped exports without making Linux glibc, Linux musl, macOS, or
Windows packaging less reliable.
