# User Documentation

This guide explains how to use and manage the Inception infrastructure.

## Available Services

| Service | Description | Access URL |
|---------|-------------|------------|
| NGINX | Entrypoint & Reverse Proxy | `https://rfirat.42.fr` |
| WordPress | CMS / Website | `https://rfirat.42.fr` |
| Adminer | Database Manager | `http://localhost:8081` |
| Static Site | Showcase Resume | `http://localhost:8080` |
| Portainer | Container Dashboard | `http://localhost:9000` |
| FTP | File Transfer | `ftp://localhost:21` |

## Getting Started

### Starting the Stack
To start all services, run the following command in the project root:
```bash
make
```

### Stopping the Stack
To stop the services while keeping data intact:
```bash
make down
```

To stop and remove everything (including volumes):
```bash
make clean
```

## Credential Management

All passwords are stored as Docker Secrets for security. You can find the source secret files in the `secrets/` directory:
- `db_password.txt`: MariaDB user password
- `db_root_password.txt`: MariaDB root password
- `wp_admin_password.txt`: WordPress admin password
- `ftp_password.txt`: FTP user password

> [!IMPORTANT]
> Never share or commit these files to a public repository.

## Health Check

To check if all services are running correctly:
1. Run `docker ps` to see the status of all containers.
2. Visit `https://rfirat.42.fr` in your browser.
3. Use `make logs` to view real-time logs for all services.
