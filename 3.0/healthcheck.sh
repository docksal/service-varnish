#!/usr/bin/env sh

netstat -nlp | grep -E 'tcp.*:80.*LISTEN.*' >/dev/null || exit 1
netstat -nlp | grep -E 'tcp.*:6082.*LISTEN.*' >/dev/null || exit 1

exit 0
