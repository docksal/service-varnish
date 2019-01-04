#!/usr/bin/env sh

netstat -nlp | grep -E 'tcp.*53.*LISTEN.*dnsmasq' >/dev/null || exit 1
netstat -nlp | grep -E 'udp.*53.*dnsmasq' >/dev/null || exit 1

exit 0
