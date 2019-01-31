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
- `VARNISH_CACHE_TAGS_HEADER` - Varnish cache header name for BAN's, default: `Cache-Tags`

## Purging cache

Varnsh cache can be purged using method "PURGE", example:

`curl -X PURGE http://varnish.tests.docksal/nonsense.html`

## BAN

You can configure BAN's using environment variable `VARNISH_CACHE_TAGS_HEADER`. Depending your environment `VARNISH_CACHE_TAGS_HEADER` cane be set to:

- [These docs on d.o](https://www.drupal.org/docs/8/api/cache-api/cache-tags-varnish) suggest `X-Cache-Tags` header should be used
- [Purger module](https://www.drupal.org/node/2692523) uses `Purge-Cache-Tags` header by default
- [Acquia Purge](https://www.drupal.org/project/acquia_purge) uses `X-Acquia-Purge-Tags`
- [Wodby](https://wodby.com/docs/stacks/drupal/containers/#drupal-8) sticks with the `Cache-Tags` header
- [Symfony FOSHttpCache](https://foshttpcache.readthedocs.io/en/stable/varnish-configuration.html#ban) uses `X-Cache-Tags`

## VCL

To provide a custom VCL config mount it at `/opt/default.vcl`.

When used with Docksal, custom VCL is automatically loaded from `.docksal/etc/varnish/default.vcl` if one exists 
in the project codebase.
