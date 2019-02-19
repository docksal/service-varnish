#!/usr/bin/env sh

# Fail if any of the health checks failed
set -e

# Check config
varnishd -C -f /etc/varnish/default.vcl

# Check port binding
netstat -nlp | grep -E 'tcp.*:80.*LISTEN.*' >/dev/null
netstat -nlp | grep -E 'tcp.*:6082.*LISTEN.*' >/dev/null
