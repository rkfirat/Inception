#!/bin/sh
set -e

# Read passwords from Docker secrets
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

cd /var/www/html

echo "Waiting for MariaDB..."
until mariadb -h mariadb -u"${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done
echo "MariaDB ready!"

if [ ! -f wp-config.php ]; then
  echo "Downloading WordPress..."
  wp core download --allow-root
  
  echo "Generating wp-config.php..."
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="mariadb:3306" \
    --allow-root
  
  echo "Installing WordPress..."
  wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --allow-root
  
  if [ "${REDIS_HOST:-}" ]; then
    echo "Configuring Redis integration..."
    wp plugin install redis-cache --activate --allow-root || true
    wp config set WP_REDIS_HOST "${REDIS_HOST}" --allow-root || true
    wp config set WP_REDIS_PORT "${REDIS_PORT}" --raw --allow-root || true
    wp redis enable --allow-root || true
  fi

  echo "Creating second user..."
  wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
    --role=editor \
    --user_pass="${WP_USER_PASSWORD}" \
    --allow-root || true
fi

chown -R www-data:www-data /var/www/html

echo "WordPress ready."
exec /usr/sbin/php-fpm8.2 -F
