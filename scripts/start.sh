#!/usr/bin/env bash
echo "==> Starting Laravel application..."

# Set working directory
cd /var/www/html

# Generate application key if not set
if ! grep -q "APP_KEY=base64:" .env; then
    echo "==> Generating application key..."
    APP_KEY="base64:$(openssl rand -base64 32)"
    sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|" .env
    echo "==> Application key generated"
fi

# Ensure database exists
mkdir -p /var/www/html/database
touch /var/www/html/database/database.sqlite
chmod 664 /var/www/html/database/database.sqlite

# Run migrations only if needed
echo "==> Running migrations..."
php artisan migrate --force --no-interaction

# Cache configuration
echo "==> Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set permissions
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html/storage
chmod -R 755 /var/www/html/bootstrap/cache

echo "==> Setup complete, starting web services..."

# Start services in background
php-fpm &
nginx &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?