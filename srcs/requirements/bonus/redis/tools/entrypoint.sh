#!/bin/sh
set -e
echo "Starting Redis..."
exec redis-server --protected-mode no --bind 0.0.0.0
