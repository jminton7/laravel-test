#!/usr/bin/env bash
echo "==> Starting Laravel application..."

# Set working directory
cd /var/www/html

# Wait a moment for file system to be ready
sleep 2

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "==> Creating .env file..."
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo "==> Copied .env from .env.example"
    else
        echo "==> Creating basic .env file..."
        cat > .env << 'EOF'
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost

LOG_CHANNEL=stderr
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DRIVER=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MEMCACHED_HOST=127.0.0.1

REDIS_HOST=127.0.0.1
REDIS_PASSWORD=null
REDIS_PORT=6379

MAIL_MAILER=smtp
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS=null
MAIL_FROM_NAME="${APP_NAME}"

AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=
AWS_USE_PATH_STYLE_ENDPOINT=false

PUSHER_APP_ID=
PUSHER_APP_KEY=
PUSHER_APP_SECRET=
PUSHER_APP_CLUSTER=mt1

MIX_PUSHER_APP_KEY="${PUSHER_APP_KEY}"
MIX_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"
EOF
    fi
    echo "==> .env file created successfully"
fi

# Check if vendor directory exists, if not install dependencies
if [ ! -d "vendor" ]; then
    echo "==> Installing Composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction
fi

# Create SQLite database if it doesn't exist
if [ ! -f "/var/www/html/database/database.sqlite" ]; then
    echo "==> Creating SQLite database..."
    mkdir -p /var/www/html/database
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