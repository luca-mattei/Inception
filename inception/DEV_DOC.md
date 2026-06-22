# Developer Documentation — Inception

This document explains how to set up, build, and manage the Inception project from a developer's perspective.

## Prerequisites

- A Linux virtual machine (Debian 12+ recommended)
- Docker Engine and Docker Compose v2
- `make`

Install Docker on Debian:

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Environment setup

From the project root, create the required secret files:

```bash
mkdir -p secrets/

# Database passwords
printf 'your_db_password'      > secrets/db_password.txt
printf 'your_root_password'    > secrets/db_root_password.txt

# WordPress credentials
cat > secrets/credentials.txt << 'EOF'
WP_ADMIN_USER=lumattei
WP_ADMIN_PASSWORD=your_admin_password
WP_ADMIN_EMAIL=lumattei@example.com
WP_USER=visiteur
WP_USER_PASSWORD=your_user_password
WP_USER_EMAIL=visiteur@example.com
EOF
```

Create the non-sensitive environment file:

```bash
cat > srcs/.env << 'EOF'
DOMAIN_NAME=lumattei.42.fr
DB_NAME=wordpress
DB_USER=wpuser
MYSQL_HOST=mariadb
EOF
```

Map the domain to localhost:

```bash
echo "127.0.0.1 lumattei.42.fr" | sudo tee -a /etc/hosts
```

Create the persistent data directories:

```bash
mkdir -p /home/lumattei/data/mariadb
mkdir -p /home/lumattei/data/wordpress
```

## Building and launching

```bash
make          # Build images, then start containers (docker compose up -d)
make build    # Build images only (docker compose build)
make up       # Start containers (docker compose up -d), creates data dirs if needed
```

The `all` target builds images then starts everything. Each service's Dockerfile is in `srcs/requirements/<service>/Dockerfile`.

## Container and volume management

```bash
# View running containers
make ps
# Equivalent: docker compose -f srcs/docker-compose.yml ps

# Follow logs
make logs
# Equivalent: docker compose -f srcs/docker-compose.yml logs -f

# Stop without data loss
make down
# Equivalent: docker compose -f srcs/docker-compose.yml down

# Stop and remove volumes (⚠️ database and WordPress files lost)
make clean
# Equivalent: docker compose -f srcs/docker-compose.yml down -v

# Full cleanup: containers, images, and host data directories
make fclean
# Runs: docker compose down -v --rmi all + rm -rf /home/lumattei/data/{mariadb,wordpress}

# Full rebuild
make re
# Equivalent: make fclean && make all
```

## Data storage and persistence

Data is stored in **named Docker volumes** backed by bind mounts on the host:

| Volume | Host path | Contents |
|--------|-----------|----------|
| `mariadb_data` | `/home/lumattei/data/mariadb` | MySQL databases, tables, users |
| `wordpress_data` | `/home/lumattei/data/wordpress` | WordPress core, themes, plugins, uploads |

These directories persist across `make down`. They are only removed with `make fclean` or `make clean`.

The volumes use the local driver with bind options — the only approach that satisfies both requirements:
- Docker named volumes (as required by the subject)
- Data stored under `/home/login/data` on the host (as required by the subject)

## Architecture details

### Build phase (Dockerfile)

Each Dockerfile:
1. Starts from `debian:bookworm`
2. Installs only the required packages
3. Copies configuration files
4. Copies the initialization script as entrypoint

No passwords, no secrets, no data initialization at build time.

### Startup phase (tools/*.sh)

Each container runs an init script at startup:

| Script | Service | What it does |
|--------|---------|--------------|
| `init-db.sh` | MariaDB | Creates database and users if first run, then starts mariadbd |
| `init-wordpress.sh` | WordPress | Waits for DB, downloads WordPress, configures and installs if first run, then starts php-fpm |
| `init-nginx.sh` | NGINX | Generates self-signed SSL cert if missing, then starts nginx |

All scripts are idempotent — they check for existing data and skip initialization on subsequent starts.

### Network

All containers are on the `inception` bridge network. Containers resolve each other by service name:
- WordPress connects to `mariadb:3306`
- NGINX proxies to `wordpress:9000`

Only NGINX exposes a port (443) to the host.

### PID 1

Each entrypoint uses `exec` to replace itself with the service process. This ensures:
- The service runs as PID 1
- Docker stop signals are received correctly
- No zombie processes
