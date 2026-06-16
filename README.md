# Inception

*This project has been created as part of the 42 curriculum by lumattei.*

A complete web hosting infrastructure built from scratch with Docker: NGINX, WordPress (php-fpm), and MariaDB, each in its own container, communicating over a private Docker network and persisting data through bind-mounted volumes.

## Description

This project sets up a small production-like environment inside a virtual machine using Docker Compose. Three services run in isolated containers:

- **NGINX** — the only entry point, serving HTTPS (TLS 1.2/1.3) on port 443 and forwarding PHP requests to WordPress.
- **WordPress + php-fpm** — the CMS, processing PHP and generating the site's pages.
- **MariaDB** — the database storing all WordPress content.

Each image is built from scratch from `debian:bookworm` (no pre-built application images). Passwords are handled via Docker secrets, kept out of version control.

## Architecture
Browser  --HTTPS:443-->  NGINX  --FastCGI:9000-->  WordPress  --MySQL:3306-->  MariaDB

Only port 443 is exposed to the host. WordPress (9000) and MariaDB (3306) are reachable only on the internal Docker network `inception`. Containers find each other by name through Docker's internal DNS.

## Requirements

- A Linux virtual machine with Docker and Docker Compose v2
- `make`
- The domain mapped locally: add `127.0.0.1 lumattei.42.fr` to `/etc/hosts`

## Setup

Before the first launch, create the secret files (not included in the repository):

```bash
mkdir -p secrets/
printf 'your_db_password'      > secrets/db_password.txt
printf 'your_root_password'    > secrets/db_root_password.txt
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_USER=lumattei
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=lumattei@example.com
WP_USER=visiteur
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=visiteur@example.com
EOF
```

Map the domain:

```bash
echo "127.0.0.1 lumattei.42.fr" | sudo tee -a /etc/hosts
```

## Usage

```bash
make          # build images and start all containers
make down     # stop and remove containers (keeps data)
make clean    # stop and remove containers + volumes
make fclean   # full cleanup: containers, images, and host data
make re       # full rebuild from scratch
make logs     # follow logs
make ps       # show container status
```

Once running, visit **https://lumattei.42.fr** (accept the self-signed certificate warning). The admin panel is at `/wp-admin`.

## Project Structure
inception/
├── Makefile
├── README.md
├── secrets/                  # not in git — created manually
└── srcs/
├── .env                  # non-sensitive config
├── docker-compose.yml
└── requirements/
├── mariadb/   { Dockerfile, conf/, tools/ }
├── nginx/     { Dockerfile, conf/, tools/ }
└── wordpress/ { Dockerfile, conf/, tools/ }

## Key Concepts

**VM vs Docker.** A virtual machine emulates a whole computer with its own kernel, started by a hypervisor — heavy and slow to boot. A Docker container shares the host kernel and packages only the application and its dependencies — lightweight and starting in seconds. Here the VM hosts Docker, and Docker hosts the three containers.

**Docker network vs host mode.** Each service joins a private bridge network where containers resolve each other by name (e.g. WordPress reaches the database simply via `mariadb`). Host network mode would remove this isolation and expose every internal port directly on the host — avoided here. Only NGINX publishes a port (443).

**Volumes vs bind mounts.** A named volume is stored in an opaque location managed by Docker. A bind mount points to a chosen host directory. The subject requires data under the host's home, so the database and WordPress files use bind-mounted volumes at `~/data/mariadb` and `~/data/wordpress` — easy to inspect and surviving container removal.

**Secrets vs environment variables.** Environment variables (and `.env` files) are visible through `docker inspect`. Docker secrets are mounted as read-only files under `/run/secrets/` and never appear in image layers or inspection output. Non-sensitive values (`DOMAIN_NAME`, `DB_NAME`, `DB_USER`, `MYSQL_HOST`) live in `.env`; all passwords use secrets.

**PID 1 and foreground processes.** Each container's entry script ends with `exec <process>` so the service becomes PID 1, runs in the foreground, and receives Docker's stop signals correctly. NGINX uses `daemon off;`, php-fpm uses `-F`, and MariaDB runs as the main process.

**Build vs run phase.** `docker compose build` produces frozen images (OS, packages, config files). The real initialization — creating the database and users, downloading and configuring WordPress, generating the SSL certificate — happens at container startup, inside the `tools/` scripts. Each script is idempotent: it skips initialization if the data already exists, so restarts are fast and non-destructive.

## Notes

- Base image is `debian:bookworm` (Debian 12), the penultimate stable Debian at build time, providing PHP 8.2.
- The SSL certificate is self-signed and generated on first start; the browser warning is expected.
- The WordPress administrator username deliberately avoids the word "admin", as required.

## Resources

- Docker documentation — https://docs.docker.com/
- NGINX documentation — https://nginx.org/en/docs/
- WP-CLI — https://wp-cli.org/
- MariaDB Knowledge Base — https://mariadb.com/kb/en/

## AI Usage Disclaimer

AI (Claude by Anthropic) was used as a learning aid to understand Docker concepts, debug configuration issues, and explain best practices. All code was reviewed, tested, and adapted to reflect genuine understanding of each component rather than copy-pasted output.
