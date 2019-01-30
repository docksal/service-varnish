# Varnish Docker images for Docksal

- Varnish 4.1
- Varnish 5.2

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Features

- BigPipe support


## Environmental variables

- `VARNISH_PORT` - port Varnish binds to, default: `80`
- `VARNISH_BACKEND_HOST` - backed-end IP/host, default: `web`
- `VARNISH_BACKEND_PORT` - backed-end port, default: `80`
- `VARNISH_CACHE_SIZE` - cache size, default: `64M`
- `VARNISH_VARNISHD_PARAMS` - extra parameters for `varnishd`.
- `VARNISH_VARNISHNCSA_PARAMS` - parameters for `varnishncsa` (logging).
- `VARNISH_SECRET` - allow the secret to be set for varnish.


## VCL

To provide a custom VCL config mount it at `/opt/default.vcl`.

When used with Docksal, custom VCL is automatically loaded from `.docksal/etc/varnish/default.vcl` if one exists 
in the project codebase.
