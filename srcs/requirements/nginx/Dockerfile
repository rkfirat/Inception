FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY tools/generate_cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/generate_cert.sh

RUN rm -f /etc/nginx/sites-enabled/default

EXPOSE 443

CMD ["/usr/local/bin/generate_cert.sh"]
