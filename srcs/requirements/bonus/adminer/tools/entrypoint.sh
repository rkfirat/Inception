#!/bin/sh
set -e

echo "Starting Adminer..."
exec php8.2 -S 0.0.0.0:8081 -t /var/www/adminer
