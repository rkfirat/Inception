#!/bin/sh
set -e

# Read FTP password from Docker secrets
FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if ! id -u "${FTP_USER}" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "${FTP_USER}"
  echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
fi

mkdir -p /var/www/html
chown -R "${FTP_USER}":"${FTP_USER}" /var/www/html

echo "Starting FTP server..."
exec /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
