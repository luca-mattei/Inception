*This project has been created as part of the 42 curriculum by lumattei.*

# Inception

A complete web hosting infrastructure built from scratch with Docker: NGINX, WordPress (php-fpm), and MariaDB — each in its own container, communicating over a private Docker network and persisting data through Docker named volumes.

## Description

This project sets up a production-like environment inside a virtual machine using Docker Compose. Three services run in isolated containers:

- **NGINX** — the single entry point, serving HTTPS (TLS 1.2/1.3) on port 443 and forwarding PHP requests to WordPress via FastCGI.
- **WordPress + php-fpm** — the CMS, processing PHP and generating site pages.
- **MariaDB** — the database storing all WordPress content.

Each image is built from `debian:bookworm` (no pre-built application images are pulled). Passwords are managed via Docker secrets and are never versioned.

## Architecture

```
Browser  --HTTPS:443-->  NGINX  --FastCGI:9000-->  WordPress  --MySQL:3306-->  MariaDB
```

Only port 443 is exposed to the host. WordPress (9000) and MariaDB (3306) are only reachable on the internal Docker network `inception`. Containers find each other by name thanks to Docker's built-in DNS.

## Prerequisites

- A Linux virtual machine with Docker and Docker Compose v2
- `make`
- The domain mapped in the VM: add `127.0.0.1 lumattei.42.fr` to `/etc/hosts`

## Installation

Before the first launch, create the secret files (not included in the repository):

```bash
mkdir -p secrets/
printf 'db_password_here'   > secrets/db_password.txt
printf 'root_password_here' > secrets/db_root_password.txt
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_USER=lumattei
WP_ADMIN_PASSWORD=admin_password_here
WP_ADMIN_EMAIL=lumattei@example.com
WP_USER=visiteur
WP_USER_PASSWORD=user_password_here
WP_USER_EMAIL=visiteur@example.com
EOF
```

Create the non-sensitive configuration file:

```bash
cat > srcs/.env << 'EOF'
DOMAIN_NAME=lumattei.42.fr
DB_NAME=wordpress
DB_USER=wpuser
MYSQL_HOST=mariadb
EOF
```

Map the domain in the VM:

```bash
echo "127.0.0.1 lumattei.42.fr" | sudo tee -a /etc/hosts
```

## Usage

```bash
make          # build images and start all containers
make down     # stop and remove containers (data preserved)
make clean    # stop and remove containers + volumes
make fclean   # full cleanup: containers, images, and host data
make re       # full rebuild from scratch
make logs     # follow logs in real time
make ps       # show container status
```

Once running, open **https://lumattei.42.fr** in the VM (accept the self-signed certificate warning). The admin panel is available at `/wp-admin`.

## Project structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                  # not versioned — create manually
└── srcs/
    ├── .env                  # non-sensitive config — not versioned
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/   { Dockerfile, .dockerignore, conf/, tools/ }
        ├── nginx/     { Dockerfile, .dockerignore, conf/, tools/ }
        └── wordpress/ { Dockerfile, .dockerignore, conf/, tools/ }
```

## Key concepts

**Virtual Machines vs Docker.** A virtual machine emulates a full computer with its own kernel, booted by a hypervisor — heavy and slow to start. A Docker container shares the host kernel and only packages the application and its dependencies — lightweight, starting in seconds. Here the VM hosts Docker, and Docker hosts the three containers.

**Docker Network vs Host Network.** Each service joins a private bridge network where containers find each other by name (e.g. WordPress reaches the database simply via `mariadb`). Using `network_mode: host` would remove this isolation and expose all internal ports directly on the host — forbidden by the project requirements. Only NGINX publishes a port (443).

**Secrets vs Environment Variables.** Environment variables (including `.env` files) are visible via `docker inspect`. Docker secrets are mounted as read-only files under `/run/secrets/` and never appear in image layers or inspect output. Non-sensitive values (`DOMAIN_NAME`, `DB_NAME`, `DB_USER`, `MYSQL_HOST`) live in `.env`; all passwords use secrets.

**Docker Volumes vs Bind Mounts.** A named volume is stored in an opaque location managed by Docker. A bind mount points to a host-chosen directory. The project requires data to reside in the user's home (`/home/lumattei/data/`), so the database and WordPress files use named volumes with the local driver and bind options — the only way to satisfy both the "named volumes" requirement and the "data in /home/login/data" constraint.

**PID 1 and foreground processes.** Each entrypoint script ends with `exec <process>` so the service becomes PID 1, runs in the foreground, and correctly receives Docker stop signals. NGINX uses `daemon off;`, php-fpm uses `-F`, and MariaDB runs as the main process.

**Build phase vs startup phase.** `docker compose build` produces frozen images (OS, packages, config files). Actual initialization — database and user creation, WordPress download and setup, SSL certificate generation — happens at container startup, in the `tools/` scripts. Each script is idempotent: it skips initialization if data already exists, so restarts are fast and non-destructive.

## Notes

- The base image is `debian:bookworm` (Debian 12), the penultimate stable version since Debian 13 (Trixie) was released in June 2025, and provides PHP 8.2.
- The SSL certificate is self-signed and generated on first startup; the browser warning is expected.
- The WordPress administrator username does not contain the word "admin", as required by the project specifications.

## Resources

- Docker Documentation — https://docs.docker.com/
- NGINX Documentation — https://nginx.org/en/docs/
- WP-CLI — https://wp-cli.org/
- MariaDB Knowledge Base — https://mariadb.com/kb/en/

## AI Usage

AI (Anthropic's Claude) was used as a learning aid to understand Docker concepts, debug configuration issues, and explain best practices. All code was reviewed, tested, and adapted to reflect genuine understanding of each component.
