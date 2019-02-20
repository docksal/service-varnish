#!/bin/bash

echo "Starting supervisord..."
exec supervisord -c /etc/supervisord.conf
