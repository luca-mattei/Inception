#!/bin/bash
set -e

echo ">>> Attente de MariaDB..."
until mariadb-admin ping -h"${MYSQL_HOST}" --silent 2>/dev/null; do
    echo "    ... MariaDB pas encore prête, on attend"
    sleep 2
done
echo ">>> MariaDB est prête."

DB_PASSWORD=$(cat /run/secrets/db_password)
source /run/secrets/credentials

cd /var/www/html

if [ -f "wp-config.php" ]; then
    echo ">>> WordPress déjà installé, démarrage direct."
else
    echo ">>> Installation de WordPress..."

    wp core download --allow-root

    wp config create \
        --dbname="${DB_NAME}" \
        --dbuser="${DB_USER}" \
        --dbpass="${DB_PASSWORD}" \
        --dbhost="${MYSQL_HOST}" \
        --allow-root

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    wp user create \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=author \
        --allow-root

    chown -R www-data:www-data /var/www/html
    echo ">>> WordPress installé."
fi

exec php-fpm8.2 -F
