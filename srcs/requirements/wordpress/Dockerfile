FROM debian:bookworm

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
    ca-certificates \
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
