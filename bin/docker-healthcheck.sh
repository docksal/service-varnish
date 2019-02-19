#!/usr/bin/env sh

# Fail if any of the health checks failed
set -e

# Check port binding
netstat -nlp | grep -E "tcp.*:${VARNISH_PORT}.*LISTEN.*" >/dev/null
netstat -nlp | grep -E "tcp.*:${VARNISH_ADMIN_PORT}.*LISTEN.*" >/dev/null
