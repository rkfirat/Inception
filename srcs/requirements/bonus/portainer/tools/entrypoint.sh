#!/bin/bash
set -e

# Portainer usually takes a few seconds to create the database file
if [ ! -f /data/portainer.db ]; then
    echo "Portainer database not found. Starting first-time setup..."
    
    # Start Portainer in background
    /app/portainer/portainer -H unix:///var/run/docker.sock &
    PORTAINER_PID=$!
    
    # Wait for Portainer to be ready
    echo "Waiting for Portainer API to become available..."
    # Portainer 2.19 handles HTTP on 9000 by default
    until curl -s http://localhost:9000/api/system/status > /dev/null; do
        sleep 2
    done
    
    USERNAME=$(cat /run/secrets/portainer_user)
    PASSWORD=$(cat /run/secrets/portainer_password_raw)
    
    echo "Initializing admin account: $USERNAME"
    
    # Perform the initialization via API
    RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "{\"Username\":\"$USERNAME\",\"Password\":\"$PASSWORD\"}" \
        http://localhost:9000/api/users/admin/init)
    
    if echo "$RESPONSE" | grep -q "User"; then
        echo "Portainer successfully initialized with user: $USERNAME"
    else
        echo "Initialization failed or user already exists: $RESPONSE"
    fi
    
    # Bring Portainer to foreground
    wait $PORTAINER_PID
else
    echo "Portainer database exists. Starting normally..."
    exec /app/portainer/portainer -H unix:///var/run/docker.sock
fi
