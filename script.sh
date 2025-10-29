#!/bin/bash

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Bağımlılıklar kontrol ediliyor...${NC}"
if ! command -v docker >/dev/null 2>&1; then
  echo -e "${RED}Docker yüklü değil. Lütfen Docker Desktop'ı kurun.${NC}"
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo -e "${RED}Docker Compose V2 bulunamadı. 'docker compose' komutu gerekli.${NC}"
  exit 1
fi

LOGIN=$(id -un)
DOMAIN_NAME="${LOGIN}.42.fr"

DB_ROOT_PASSWORD=$(openssl rand -base64 12)
DB_USER_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
FTP_PASSWORD=$(openssl rand -base64 12)

# 42 subject'e uygun host yolunu hedefle, yoksa $HOME altında oluştur
DEFAULT_DATA_DIR="/home/${LOGIN}/data"
HOST_DATA_DIR="${DEFAULT_DATA_DIR}"
if [ ! -d "/home/${LOGIN}" ]; then
  echo -e "${YELLOW}/home/${LOGIN} mevcut değil, ${HOME}/data kullanılacak.${NC}"
  HOST_DATA_DIR="${HOME}/data"
fi

# /etc/hosts düzenlemesi için uyarı
echo -e "${YELLOW}Not: ${DOMAIN_NAME} için /etc/hosts düzenlemesi gerekiyor.${NC}"
if ! grep -q "${DOMAIN_NAME}" /etc/hosts 2>/dev/null; then
  echo -e "${YELLOW}Şu komutu çalıştırmanız gerekebilir:${NC}"
  echo -e "${GREEN}sudo sh -c 'echo \"127.0.0.1 ${DOMAIN_NAME}\" >> /etc/hosts'${NC}"
fi

echo -e "${GREEN}Proje dizinleri ve dosyaları oluşturuluyor...${NC}"

# Zorunlu servisler
mkdir -p \
  srcs/requirements/mariadb/tools \
  srcs/requirements/nginx/conf srcs/requirements/nginx/tools \
  srcs/requirements/wordpress/tools srcs/requirements/wordpress/conf

# Bonus servisler
mkdir -p \
  srcs/requirements/bonus/redis/tools srcs/requirements/bonus/redis/conf \
  srcs/requirements/bonus/ftp/tools srcs/requirements/bonus/ftp/conf \
  srcs/requirements/bonus/static_website/tools srcs/requirements/bonus/static_website/conf

# MariaDB Dockerfile
cat > srcs/requirements/mariadb/Dockerfile <<'MARIADB_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 777 /var/run/mysqld

RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mariadb.conf.d/50-server.cnf && \
    sed -i 's/skip-networking/#skip-networking/g' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

CMD ["/usr/local/bin/init_db.sh"]
MARIADB_DOCKER

# WordPress Dockerfile
cat > srcs/requirements/wordpress/Dockerfile <<'WP_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-cli \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-redis \
    curl \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf && \
    mkdir -p /run/php && \
    mkdir -p /var/www/html && \
    chown -R www-data:www-data /var/www/html

COPY tools/setup_wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_wp.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/local/bin/setup_wp.sh"]
WP_DOCKER

# NGINX Dockerfile
cat > srcs/requirements/nginx/Dockerfile <<'NGINX_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/generate_cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_cert.sh

RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

CMD ["/usr/local/bin/generate_cert.sh"]
NGINX_DOCKER

# Redis Dockerfile
cat > srcs/requirements/bonus/redis/Dockerfile <<'REDIS_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    redis-server \
    && rm -rf /var/lib/apt/lists/*

COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 6379

CMD ["/usr/local/bin/entrypoint.sh"]
REDIS_DOCKER

# FTP Dockerfile
cat > srcs/requirements/bonus/ftp/Dockerfile <<'FTP_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 21000-21010

CMD ["/usr/local/bin/entrypoint.sh"]
FTP_DOCKER

# Static Website Dockerfile
cat > srcs/requirements/bonus/static_website/Dockerfile <<'STATIC_DOCKER'
FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    nginx \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/static

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/build.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build.sh

RUN echo '<!DOCTYPE html><html><head><title>Static Site</title></head><body><h1>Welcome to Static Website</h1></body></html>' > /var/www/static/index.html

EXPOSE 80

CMD ["/usr/local/bin/build.sh"]
STATIC_DOCKER

# MariaDB init script
cat > srcs/requirements/mariadb/tools/init_db.sh <<'MARIADB_INIT'
#!/bin/sh
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "MariaDB veri dizini başlatılıyor..."
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
fi

chown -R mysql:mysql /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld

tempfile=$(mktemp)
cat << SQL > "$tempfile"
USE mysql;
FLUSH PRIVILEGES;
DELETE FROM mysql.global_priv WHERE User='';
DELETE FROM mysql.global_priv WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
SQL

/usr/bin/mariadbd --user=mysql --bootstrap < "$tempfile"
rm -f "$tempfile"

echo "MariaDB hazır."
exec /usr/bin/mariadbd --user=mysql --bind-address=0.0.0.0
MARIADB_INIT
chmod +x srcs/requirements/mariadb/tools/init_db.sh

# WordPress setup script
cat > srcs/requirements/wordpress/tools/setup_wp.sh <<'WP_SETUP'
#!/bin/sh
set -e

cd /var/www/html

echo "MariaDB bekleniyor..."
until mariadb -h mariadb -u"${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done
echo "MariaDB hazır!"

if [ ! -f wp-config.php ]; then
  echo "WordPress indiriliyor..."
  wp core download --allow-root
  
  echo "wp-config.php oluşturuluyor..."
  wp config create \
    --dbname="${DB_NAME}" \
    --dbuser="${DB_USER}" \
    --dbpass="${DB_PASSWORD}" \
    --dbhost="mariadb:3306" \
    --allow-root
  
  echo "WordPress kurulumu yapılıyor..."
  wp core install \
    --url="https://${DOMAIN_NAME}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --allow-root
  
  if [ "${REDIS_HOST:-}" ]; then
    echo "Redis entegrasyonu yapılıyor..."
    wp plugin install redis-cache --activate --allow-root || true
    wp config set WP_REDIS_HOST "${REDIS_HOST}" --allow-root || true
    wp config set WP_REDIS_PORT "${REDIS_PORT}" --raw --allow-root || true
    wp redis enable --allow-root || true
  fi
fi

chown -R www-data:www-data /var/www/html

echo "WordPress hazır."
exec /usr/sbin/php-fpm8.2 -F
WP_SETUP
chmod +x srcs/requirements/wordpress/tools/setup_wp.sh

# NGINX SSL certificate generator
cat > srcs/requirements/nginx/tools/generate_cert.sh <<'NGINX_CERT'
#!/bin/sh
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
  echo "Self-signed SSL sertifikası oluşturuluyor..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=TR/ST=Istanbul/L=Istanbul/O=42/OU=42/CN=${DOMAIN_NAME}"
fi

echo "SSL sertifikası hazır."
exec nginx -g "daemon off;"
NGINX_CERT
chmod +x srcs/requirements/nginx/tools/generate_cert.sh

# Redis entrypoint
cat > srcs/requirements/bonus/redis/tools/entrypoint.sh <<'REDIS_ENTRY'
#!/bin/sh
set -e
echo "Redis başlatılıyor..."
exec redis-server --protected-mode no --bind 0.0.0.0
REDIS_ENTRY
chmod +x srcs/requirements/bonus/redis/tools/entrypoint.sh

# FTP entrypoint
cat > srcs/requirements/bonus/ftp/tools/entrypoint.sh <<'FTP_ENTRY'
#!/bin/sh
set -e

if ! id -u "${FTP_USER}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${FTP_USER}"
  echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

mkdir -p /var/www/html
chown -R "${FTP_USER}":"${FTP_USER}" /var/www/html

echo "FTP server başlatılıyor..."
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
FTP_ENTRY
chmod +x srcs/requirements/bonus/ftp/tools/entrypoint.sh

# Static website
cat > srcs/requirements/bonus/static_website/tools/build.sh <<'STATIC_BUILD'
#!/bin/sh
set -e
echo "Static website hazır."
exec nginx -g "daemon off;"
STATIC_BUILD
chmod +x srcs/requirements/bonus/static_website/tools/build.sh

# NGINX default.conf
cat > srcs/requirements/nginx/conf/default.conf <<'NGINX_CONF'
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    
    server_name localhost;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/html;
    index index.php index.html;
    
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }
}
NGINX_CONF

# FTP vsftpd.conf
cat > srcs/requirements/bonus/ftp/conf/vsftpd.conf <<'FTP_CONF'
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_local_user=YES
allow_writeable_chroot=YES
seccomp_sandbox=NO
pasv_enable=YES
pasv_min_port=21000
pasv_max_port=21010
user_sub_token=$USER
local_root=/var/www/html
FTP_CONF

# Static website nginx conf
cat > srcs/requirements/bonus/static_website/conf/default.conf <<'STATIC_CONF'
server {
    listen 80;
    listen [::]:80;
    
    root /var/www/static;
    index index.html;
    
    location / {
        try_files $uri $uri/ =404;
    }
}
STATIC_CONF

echo -e "${GREEN}Dizinler ve boş dosyalar oluşturuldu.${NC}"

echo -e "${GREEN}srcs/.env dosyası oluşturuluyor...${NC}"
mkdir -p srcs
cat > srcs/.env <<EOL
USER_LOGIN=${LOGIN}
DOMAIN_NAME=${DOMAIN_NAME}

# Host bind mount path (42 subject: /home/LOGIN/data)
DATA_DIR=${HOST_DATA_DIR}

DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=${DB_USER_PASSWORD}
DB_ROOT_PASSWORD=${DB_ROOT_PASSWORD}

WP_TITLE=Inception
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}
WP_ADMIN_EMAIL=admin@${DOMAIN_NAME}

FTP_USER=ftpuser
FTP_PASSWORD=${FTP_PASSWORD}

REDIS_HOST=redis
REDIS_PORT=6379
EOL
echo -e "${GREEN}srcs/.env oluşturuldu.${NC}"

echo -e "${GREEN}Veri dizinleri oluşturuluyor...${NC}"
mkdir -p "${HOST_DATA_DIR}/wordpress" "${HOST_DATA_DIR}/mariadb"
echo -e "${GREEN}Veri dizinleri hazır: ${HOST_DATA_DIR}/{wordpress,mariadb}${NC}"

echo -e "${GREEN}docker-compose.yml oluşturuluyor...${NC}"
cat > srcs/docker-compose.yml <<'YAML'
version: "3.8"

services:
  mariadb:
    container_name: mariadb
    build:
      context: ./requirements/mariadb
      dockerfile: Dockerfile
    volumes:
      - mariadb:/var/lib/mysql
    networks:
      - inception
    restart: unless-stopped
    env_file:
      - .env
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "root", "-p${DB_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

  wordpress:
    container_name: wordpress
    build:
      context: ./requirements/wordpress
      dockerfile: Dockerfile
    volumes:
      - wordpress:/var/www/html
    networks:
      - inception
    depends_on:
      mariadb:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped
    env_file:
      - .env

  nginx:
    container_name: nginx
    build:
      context: ./requirements/nginx
      dockerfile: Dockerfile
    volumes:
      - wordpress:/var/www/html:ro
    ports:
      - "443:443"
    networks:
      - inception
    depends_on:
      - wordpress
    restart: unless-stopped
    env_file:
      - .env

  redis:
    container_name: redis
    build:
      context: ./requirements/bonus/redis
      dockerfile: Dockerfile
    networks:
      - inception
    restart: unless-stopped

  ftp:
    container_name: ftp
    build:
      context: ./requirements/bonus/ftp
      dockerfile: Dockerfile
    volumes:
      - wordpress:/var/www/html
    ports:
      - "21:21"
      - "21000-21010:21000-21010"
    networks:
      - inception
    depends_on:
      - wordpress
    restart: unless-stopped
    env_file:
      - .env

  static_website:
    container_name: static_website
    build:
      context: ./requirements/bonus/static_website
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    networks:
      - inception
    restart: unless-stopped

volumes:
  wordpress:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/wordpress
  mariadb:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ${DATA_DIR}/mariadb

networks:
  inception:
    name: inception
    driver: bridge
YAML
echo -e "${GREEN}docker-compose.yml iskeleti oluşturuldu.${NC}"

echo -e "${GREEN}Makefile oluşturuluyor...${NC}"
cat > Makefile <<'EOL'
.PHONY: all up down clean fclean re logs

COMPOSE = docker compose -f srcs/docker-compose.yml --env-file srcs/.env
DATA_DIR := $(shell awk -F= '/^DATA_DIR=/{print $$2}' srcs/.env)

all: up

up:
	@echo "Veri dizinleri hazırlanıyor: $(DATA_DIR)"
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	@echo "Konteynerlar başlatılıyor..."
	@$(COMPOSE) up -d --build | cat

down:
	@echo "Konteynerlar durduruluyor..."
	@$(COMPOSE) down

logs:
	@$(COMPOSE) logs -f | cat

clean:
	@echo "Konteynerlar ve bağlı objeler kaldırılıyor..."
	@$(COMPOSE) down -v

fclean:
	@echo "Görüntüler ve veriler temizleniyor..."
	@$(COMPOSE) down -v --rmi local || true
	@rm -rf $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	@rm -f srcs/.env

re: fclean up
EOL
echo -e "${GREEN}Makefile oluşturuldu.${NC}"

echo -e "${GREEN}Kurulum tamamlandı! Dockerfile ve konfigürasyon dosyalarını şimdi doldurabilirsin.${NC}"