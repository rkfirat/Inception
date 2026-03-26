FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Download and extract Portainer CE 2.19.4 (latest stable)
RUN mkdir -p /app /data && \
    curl -L https://github.com/portainer/portainer/releases/download/2.19.4/portainer-2.19.4-linux-amd64.tar.gz | tar xz -C /app && \
    chmod -R 755 /data

COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /app

EXPOSE 9000 8000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
