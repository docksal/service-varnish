# Varnish Docker images for Docksal

- Varnish 3.0 (deprecated and unsupported)
- Varnish 4.1
- Varnish 5.2

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Features

The following feature were added on top of the Fourkitchens config:

- BigPipe support


## Environmental variables

- `VARNISH_PORT` - port Varnish binds to, default: `80`
- `VARNISH_BACKEND_HOST` - backed-end IP/host, default: `web`
- `VARNISH_BACKEND_PORT` - backed-end port, default: `80`
- `VARNISH_CACHE_SIZE` - cache size, default: `64M`
- `VARNISH_VARNISHD_PARAMS` - extra parameters for `varnishd`.
- `VARNISH_VARNISHNCSA_PARAMS` - parameters for `varnishncsa` (logging).
- `VARNISH_SECRET` - allow the secret to be set for varnish.
- `VARNISH_IP_CLEAR` - IP Addresses to allow for clearing cache.

## VCL

The default VCL is based on:

https://fourkitchens.atlassian.net/wiki/display/TECH/Configure+Varnish+3+for+Drupal+7

To provide a custom VCL config mount it at `/opt/default.vcl`.

When used with Docksal, custom VCL is automatically loaded from `.docksal/etc/varnish/default.vcl` if one exists 
in the project codebase.
