#!/bin/sh
set -e
echo "Static website ready."
exec python3 -m http.server 80 --directory /var/www/static
