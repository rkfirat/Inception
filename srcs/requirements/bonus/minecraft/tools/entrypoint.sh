#!/bin/bash
set -e

MINECRAFT_VERSION="latest"
SERVER_JAR="server.jar"

cd /minecraft

# Download Minecraft server if not exists
if [ ! -f "$SERVER_JAR" ]; then
  echo "PaperMC sunucusu (1.20.1) indiriliyor..."
  wget -q https://api.papermc.io/v2/projects/paper/versions/1.20.1/builds/196/downloads/paper-1.20.1-196.jar -O "$SERVER_JAR"
fi

# Accept EULA automatically
echo "eula=true" > eula.txt

echo "Starting Minecraft server..."

# Run Minecraft server in foreground
exec java -Xmx2048M -Xms2048M -XX:+UseG1GC -jar "$SERVER_JAR" nogui
