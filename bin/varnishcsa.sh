#!/bin/bash

echo 'Starting varnishncsa for log streaming...'
exec su-exec varnish varnishncsa ${VARNISH_VARNISHNCSA_PARAMS}
