#!/bin/bash
set -e

if [ ! -d "/var/lib/mysql/mysql" ]; then
    DB_PASSWORD=$(cat /run/secrets/db_password)
    DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db

    mariadbd --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
EOF
fi

exec mariadbd --user=mysql
