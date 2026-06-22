# User Documentation — Inception

This document explains how to use the Inception stack as an end user or administrator.

## Services provided

The stack runs three services in Docker containers:

| Service | Role | Access |
|---------|------|--------|
| **NGINX** | Web server, TLS termination | Public — port 443 (HTTPS) |
| **WordPress + php-fpm** | Content management system | Via NGINX only |
| **MariaDB** | Relational database | Internal only |

The website is a fully functional WordPress instance, ready for content creation.

## Starting and stopping

All operations use the `Makefile` at the project root:

```bash
make          # Build images and start all containers
make down     # Stop and remove containers (data is preserved)
make stop     # Stop containers without removing them
make start    # Start previously stopped containers
make clean    # Stop containers and delete volumes (⚠️ data loss)
make fclean   # Full cleanup: containers, images, and host data
```

## Accessing the website

Open **https://lumattei.42.fr** in a browser running on the virtual machine.

The certificate is self-signed — accept the security warning on first visit.

### Admin panel

Go to **https://lumattei.42.fr/wp-admin** and log in with:

- **Username**: `lumattei`
- **Password**: the value of `WP_ADMIN_PASSWORD` in `secrets/credentials.txt`

### Regular user

A second user exists for content creation:

- **Username**: `visiteur`
- **Password**: the value of `WP_USER_PASSWORD` in `secrets/credentials.txt`

## Managing credentials

All credentials are stored in the `secrets/` directory (not versioned by git):

```
secrets/
├── db_password.txt         # WordPress database user password
├── db_root_password.txt    # MariaDB root password
└── credentials.txt         # WordPress admin and user credentials
```

To change a password:
1. Edit the corresponding file in `secrets/`
2. Run `make re` to rebuild and restart

## Checking service health

```bash
make ps        # Show container status
make logs      # Follow live logs from all containers
```

Or manually:

```bash
docker compose -f srcs/docker-compose.yml ps
docker compose -f srcs/docker-compose.yml logs -f
```

Healthy output should show all three containers with status **Up**:

```
NAME        STATUS
mariadb     Up (healthy)
wordpress   Up
nginx       Up
```
