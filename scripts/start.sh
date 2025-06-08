#!/usr/bin/env bash
echo "==> Starting Laravel application..."

# Set working directory
cd /var/www/html

# Wait a moment for file system to be ready
sleep 2

# Check if vendor directory exists, if not install dependencies
if [ ! -d "vendor" ]; then
    echo "==> Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
fi

# Create SQLite database if it doesn't exist
if [ ! -f "/var/www/html/database/database.sqlite" ]; then
    echo "==> Creating SQLite database..."
    touch /var/www/html/database/database.sqlite
fi

# Generate application key if not set
echo "==> Generating application key..."
php artisan key:generate --force

# Run database migrations
echo "==> Running migrations..."
php artisan migrate --force

# Cache configuration for better performance
echo "==> Caching configuration..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set proper permissions
echo "==> Setting permissions..."
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html/storage
chmod -R 755 /var/www/html/bootstrap/cache
chmod 664 /var/www/html/database/database.sqlite

echo "==> Starting nginx and php-fpm..."
# Start the original start script from the base image
exec /start.sh