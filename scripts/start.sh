#!/usr/bin/env bash
echo "==> Starting Laravel application..."

# Set working directory
cd /var/www/html

# Wait a moment for file system to be ready
sleep 2

# Create .env file if it doesn't exist (backup in case Docker didn't create it)
if [ ! -f ".env" ]; then
    echo "==> Creating .env file..."
    cat > .env << 'EOF'
APP_NAME=Laravel
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://localhost
LOG_CHANNEL=stderr
DB_CONNECTION=sqlite
DB_DATABASE=/var/www/html/database/database.sqlite
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
EOF
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
# Check if APP_KEY is empty in .env file
if ! grep -q "APP_KEY=base64:" .env; then
    echo "==> APP_KEY not found or empty, generating new key..."
    
    # Try the standard artisan command first
    if php artisan key:generate --force --no-interaction 2>/dev/null; then
        echo "==> Application key generated successfully with artisan"
    else
        echo "==> Artisan key:generate failed, generating key manually..."
        # Generate a 32-byte random key and encode it
        APP_KEY="base64:$(openssl rand -base64 32)"
        
        # Replace the empty APP_KEY in .env file
        if grep -q "APP_KEY=" .env; then
            sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|" .env
        else
            echo "APP_KEY=$APP_KEY" >> .env
        fi
        
        echo "==> Application key set manually: $APP_KEY"
        
        # Verify the key was set
        if grep -q "$APP_KEY" .env; then
            echo "==> Key verification successful"
        else
            echo "==> ERROR: Key verification failed"
        fi
    fi
else
    echo "==> APP_KEY already exists in .env file"
fi

# Show current APP_KEY status
echo "==> Current APP_KEY in .env:"
grep "APP_KEY=" .env || echo "No APP_KEY found"

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