FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    php8.2 \
    php8.2-mysql \
    php8.2-cli \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/adminer && \
    wget -q https://github.com/vrana/adminer/releases/download/v5.4.2/adminer-5.4.2-en.php \
    -O /var/www/adminer/index.php

COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8081

CMD ["/usr/local/bin/entrypoint.sh"]
