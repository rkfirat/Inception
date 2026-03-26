FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    vsftpd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd/vsftpd.conf
COPY tools/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 21 21000-21010

CMD ["/usr/local/bin/entrypoint.sh"]
