# Developer Documentation

## Environment Setup

### Prerequisites
- Debian-based virtual machine
- Docker Engine and Docker Compose installed
- User added to `docker` group: `/sbin/usermod -aG docker <user>`

### Configuration Files
| File                    | Purpose                               |
|-------------------------|---------------------------------------|
| `srcs/.env`             | Environment variables (non-sensitive) |
| `srcs/.env.example`     | Template for `.env`                   |
| `secrets/*.txt`         | Docker secrets (passwords)            |
| `secrets/credentials.txt` | Human-readable credential summary  |

### Initial Setup
```bash
# 1. Clone the repository
git clone <repo_url> && cd Inception

# 2. Create .env from template (auto-done by Makefile)
cp srcs/.env.example srcs/.env

# 3. Update secrets in secrets/ directory
# 4. Add domain to /etc/hosts
echo "127.0.0.1 rfirat.42.fr" | sudo tee -a /etc/hosts

# 5. Build and launch
make
```

## Build and Launch

The `Makefile` at project root orchestrates everything:

```bash
make          # Creates data dirs, builds images, starts containers
make down     # Stops containers
make logs     # Streams all container logs
make clean    # Stops containers and removes volumes
make fclean   # Full cleanup: images, volumes, data directories, .env
make re       # fclean + up (full rebuild)
```

### Docker Compose
```bash
# Build a specific service
docker compose -f srcs/docker-compose.yml --env-file srcs/.env build <service>

# Restart a single service
docker compose -f srcs/docker-compose.yml --env-file srcs/.env up -d --build <service>
```

## Container Management

```bash
# List containers
docker ps

# View logs
docker logs <container_name>
docker logs -f <container_name>  # follow mode

# Execute command inside container
docker exec -it <container_name> sh

# Access Minecraft console
docker attach minecraft  # Detach with Ctrl+P, Ctrl+Q
```

## Data Persistence

All persistent data is stored on the host at `DATA_DIR` (default: `/home/user/data`):

| Directory                  | Content                          |
|----------------------------|----------------------------------|
| `$DATA_DIR/wordpress`      | WordPress files (themes, plugins)|
| `$DATA_DIR/mariadb`        | MariaDB database files           |
| `$DATA_DIR/minecraft`      | Minecraft world and server files |
| `$DATA_DIR/portainer`      | Portainer configuration          |

Docker named volumes are configured with `driver: local` and bind to these host paths via `driver_opts`.

## Project Structure

```
Inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── .env
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/         # MariaDB database
        ├── nginx/           # NGINX reverse proxy
        ├── wordpress/       # WordPress + PHP-FPM
        └── bonus/
            ├── adminer/     # Adminer DB manager
            ├── ftp/         # FTP server
            ├── minecraft/   # PaperMC server
            ├── portainer/   # Portainer dashboard
            ├── redis/       # Redis cache
            └── static_website/  # Static HTML site
```

## Adding a New Service

1. Create directory: `srcs/requirements/bonus/<service>/`
2. Add `Dockerfile`, `tools/entrypoint.sh`, and optional `conf/`
3. Add service definition in `srcs/docker-compose.yml`
4. If persistent storage needed, add volume definition
5. Update `Makefile` data directory creation and cleanup
