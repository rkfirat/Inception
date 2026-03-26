*This project has been created as part of the 42 curriculum by rfirat.*

# Inception

## Description

Inception is a system administration project that uses Docker to set up a complete multi-service web infrastructure inside a virtual machine. The goal is to build and configure each Docker image from scratch using `Dockerfile`s, orchestrated by `docker-compose`.

The infrastructure includes:
- **NGINX** — Reverse proxy with TLSv1.2/TLSv1.3 (only entrypoint, port 443)
- **WordPress** + **PHP-FPM** — Content management system
- **MariaDB** — Relational database for WordPress
- **Redis** — Object cache for WordPress performance (bonus)
- **FTP** — File transfer pointing to WordPress volume (bonus)
- **Adminer** — Lightweight database management UI (bonus)
- **Static Website** — A simple static site served by NGINX (bonus)
- **Portainer** — Docker container management dashboard (bonus)
- **Minecraft** — A PaperMC game server (bonus)

## Instructions

### Prerequisites
- A Linux virtual machine (Debian recommended)
- Docker and Docker Compose installed
- Ports 443, 8080, 8081, 9000, 21, 25565 available

### Build & Run
```bash
make        # Build and start all services
make down   # Stop all services
make logs   # View container logs
make clean  # Stop and remove volumes
make fclean # Full cleanup (images + data)
make re     # Full rebuild
```

### Access
| Service         | URL / Port                        |
|-----------------|-----------------------------------|
| WordPress       | `https://rfirat.42.fr`           |
| Adminer         | `http://localhost:8081`            |
| Static Website  | `http://localhost:8080`            |
| Portainer       | `http://localhost:9000`            |
| FTP             | `ftp://localhost:21`               |
| Minecraft       | `localhost:25565`                  |

## Project Description

### Docker Usage
Each service runs in an isolated Docker container built from `debian:bookworm`. No pre-built images from DockerHub are used. All images are built via custom `Dockerfile`s called from `docker-compose.yml` through the `Makefile`.

### Virtual Machines vs Docker
| Aspect          | Virtual Machine             | Docker Container             |
|-----------------|-----------------------------|------------------------------|
| Isolation       | Full OS-level (hypervisor)  | Process-level (kernel shared)|
| Size            | GBs (full OS image)         | MBs (layered filesystem)    |
| Startup time    | Minutes                     | Seconds                      |
| Resource usage  | High (dedicated resources)  | Low (shared kernel)          |

### Secrets vs Environment Variables
| Aspect            | Environment Variables        | Docker Secrets               |
|-------------------|------------------------------|------------------------------|
| Storage           | `.env` file, in memory       | Encrypted, tmpfs mounted     |
| Access            | All processes in container   | Only via `/run/secrets/`     |
| Use case          | Non-sensitive config         | Passwords, API keys          |
| Security          | Visible in `docker inspect`  | Never exposed in logs/inspect|

### Docker Network vs Host Network
| Aspect            | Docker Network (bridge)      | Host Network                 |
|-------------------|------------------------------|------------------------------|
| Isolation         | Containers on private subnet | Shares host network stack    |
| Port mapping      | Explicit via `ports:`        | Automatic, all ports exposed |
| Security          | Better (isolated)            | Worse (no isolation)         |
| Performance       | Slight overhead              | Native performance           |

### Docker Volumes vs Bind Mounts
| Aspect            | Docker Volumes               | Bind Mounts                  |
|-------------------|------------------------------|------------------------------|
| Management        | Managed by Docker            | Host path directly           |
| Portability       | Portable across hosts        | Host-dependent               |
| Backup            | Via `docker volume` commands | Standard file tools          |
| Permission        | Docker handles               | Must match host permissions  |

## Resources

- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [WordPress CLI Documentation](https://developer.wordpress.org/cli/commands/)
- [NGINX Configuration Guide](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [PaperMC Documentation](https://docs.papermc.io/)

### AI Usage
AI was used as an assistant for:
- Generating boilerplate `Dockerfile` and configuration templates
- Debugging container startup issues
- Optimizing Minecraft server performance (PaperMC migration)
- Drafting documentation structure

All AI-generated content was reviewed, tested, and validated manually.
