FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    wget \
    curl \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/minecraft && \
    mkdir -p /minecraft

WORKDIR /minecraft

COPY conf/server.properties /minecraft/server.properties
COPY conf/ops.json /minecraft/ops.json
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 25565

CMD ["/usr/local/bin/entrypoint.sh"]
