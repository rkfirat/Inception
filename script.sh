#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

# Proje dizinlerini ve dosyalarını oluşturma
echo -e "${GREEN}Proje dizinleri ve dosyaları oluşturuluyor...${NC}"
mkdir -p srcs/requirements/mariadb srcs/requirements/nginx srcs/requirements/wordpress \
         srcs/requirements/ftp srcs/requirements/redis srcs/requirements/static_website
touch srcs/docker-compose.yml srcs/requirements/wordpress.conf srcs/requirements/mariadb.conf \
      srcs/requirements/nginx.conf srcs/requirements/mariadb/Dockerfile \
      srcs/requirements/nginx/Dockerfile srcs/requirements/wordpress/Dockerfile \
      srcs/requirements/mariadb/tools.sh srcs/requirements/nginx/tools.sh \
      srcs/requirements/wordpress/tools.sh srcs/requirements/ftp/Dockerfile \
      srcs/requirements/redis/Dockerfile srcs/requirements/static_website/Dockerfile \
      srcs/requirements/ftp.conf srcs/requirements/redis.conf srcs/requirements/static_website.conf
echo -e "${GREEN}Dizinler ve dosyalar başarıyla oluşturuldu.${NC}"

echo -e "${GREEN}.env dosyası oluşturuluyor...${NC}"
USER_NAME=$(whoami)
DOMAIN_NAME="$USER_NAME.42.fr"
DB_ROOT_PASSWORD=$(openssl rand -base64 12)
DB_USER_PASSWORD=$(openssl rand -base64 12)
WP_ADMIN_PASSWORD=$(openssl rand -base64 12)
FTP_PASSWORD=$(openssl rand -base64 12)

cat > .env <<EOL
USER=$USER_NAME
DATA_ROOT=/home/$USER_NAME/data

DB_NAME=wordpress_db
DB_USER=wordpress_user
DB_PASSWORD=$DB_USER_PASSWORD
DB_ROOT_PASSWORD=$DB_ROOT_PASSWORD

WP_TITLE=Inception
WP_USER=admin
WP_PASSWORD=$WP_ADMIN_PASSWORD
WP_EMAIL=admin@$DOMAIN_NAME

FTP_USER=ftpuser
FTP_PASSWORD=$FTP_PASSWORD

DOMAIN_NAME=$DOMAIN_NAME
EOL
echo -e "${GREEN}.env dosyası başarıyla oluşturuldu.${NC}"

echo -e "${GREEN}Makefile dosyası oluşturuluyor...${NC}"
cat > Makefile <<EOL
.PHONY: all setup start stop clean fclean re

all: start

setup:
	@echo "Proje dosya yapısı zaten oluşturuldu."

start:
	@echo "Konteynerlar başlatılıyor..."
	@docker-compose up -d --build

stop:
	@echo "Konteynerlar durduruluyor..."
	@docker-compose down

clean: stop
	@echo "Konteynerlar siliniyor..."
	@docker-compose rm -f

fclean: stop
	@echo "Tüm veriler ve imajlar siliniyor..."
	@docker-compose down -v --rmi all
	@rm -f .env

re: fclean start

EOL
echo -e "${GREEN}Makefile dosyası başarıyla oluşturuldu.${NC}"

echo -e "${GREEN}Kurulum tamamlandı! Şimdi Dockerfile'ları ve diğer konfigürasyon dosyalarını doldurabilirsin.${NC}"
