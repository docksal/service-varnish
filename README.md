# Varnish Docker images for Docksal

- Varnish 3
- Varnish 4

This image(s) is part of the [Docksal](http://docksal.io) image library.


## Environmental variables

- `VARNISH_PORT` - port Varnish binds to, default: `80`
- `VARNISH_BACKEND_HOST` - **must set this** to the web container IP/hostname
- `VARNISH_BACKEND_PORT` - web container port, default: `80`
- `VARNISH_CACHE_SIZE` - cache size, default: `64M`
- `VARNISH_VARNISHD_PARAMS` - extra parameters for `varnishd`
- `VARNISH_VARNISHLOG_PARAMS` - parameters for `varnishlog`, default: `-c -m TxStatus:^50` (Log failing (client side) requests)


## VCL

The default VCL is based on:

https://fourkitchens.atlassian.net/wiki/display/TECH/Configure+Varnish+3+for+Drupal+7

To provide a custom vcl config mount it at `/opt/default.vcl`.


## Features

The following feature were added on top of the Fourkitchens config:

- BigPipe support
