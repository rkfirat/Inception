FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/static

COPY tools/build.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/build.sh

RUN echo '<!DOCTYPE html><html><head><title>Static Site</title></head><body><h1>Welcome to Static Website</h1></body></html>' > /var/www/static/index.html

EXPOSE 80

CMD ["/usr/local/bin/build.sh"]
