# Difference between Varnish 3.0 and 4.1 vcl file.

VCL for Varnish 4 and 4.1 versions should contain `vcl 4.0;` directive.

## Renamed methods
- `vcl_fetch` => `vcl_backend_response`
- `vcl_error` => `vcl_backend_error`

## Renamed variables
- `req.request` => `req.method`
- `obj` in `vcl_error` => `beresp` in `vcl_backend_error`
- `req.*` not available in `vcl_backend_response` => `bereq.*`
- `req.backend.healthy` => `std.healthy(req.backend_hint)` (NOTE: use `import std;` after `vcl 4.0;` directive to import std VMOD)
- `client.port` => `std.port(client.ip)`
- `server.port` => `std.port(server.ip)`

## Renamed functions, removed keywords or keywords moved to functions
- `error()` => `synth()`
- `purge` keyword removed => `return(purge)`
- `synthetic` keyword => `synthetic()` function
- `remove` => `unset`
