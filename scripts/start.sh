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
APP_URL=https://laravel-test-fzx8.onrender.com
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

# Create SQLite database directory and file with proper permissions
echo "==> Setting up SQLite database..."
mkdir -p /var/www/html/database
touch /var/www/html/database/database.sqlite
chmod 664 /var/www/html/database/database.sqlite
chown nginx:nginx /var/www/html/database/database.sqlite

# Generate application key if not set
echo "==> Generating application key..."
echo "==> Current directory: $(pwd)"
echo "==> .env file exists: $(test -f .env && echo 'YES' || echo 'NO')"

# Check if APP_KEY is empty in .env file
if ! grep -q "APP_KEY=base64:" .env; then
    echo "==> APP_KEY not found or empty, generating new key..."
   
    # Generate key manually since artisan seems to have issues
    echo "==> Generating key manually with openssl..."
    APP_KEY="base64:$(openssl rand -base64 32)"
   
    # Replace the empty APP_KEY in .env file
    if grep -q "APP_KEY=" .env; then
        sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|" .env
        echo "==> Replaced existing APP_KEY line"
    else
        echo "APP_KEY=$APP_KEY" >> .env
        echo "==> Added new APP_KEY line"
    fi
   
    echo "==> Application key set manually: $APP_KEY"
else
    echo "==> APP_KEY already exists in .env file"
fi

# Test database connection before migrations
echo "==> Testing database connection..."
if php artisan tinker --execute="DB::connection()->getPdo(); echo 'Database connection successful';" 2>/dev/null; then
    echo "==> Database connection test passed"
    
    # Run database migrations with timeout
    echo "==> Running migrations..."
    timeout 60 php artisan migrate --force
    if [ $? -eq 0 ]; then
        echo "==> Migrations completed successfully"
    else
        echo "==> WARNING: Migrations timed out or failed, continuing anyway..."
    fi
else
    echo "==> WARNING: Database connection failed, skipping migrations"
fi

# Cache configuration for better performance
echo "==> Caching configuration..."
php artisan config:cache 2>/dev/null || echo "Config cache failed, continuing..."
php artisan route:cache 2>/dev/null || echo "Route cache failed, continuing..."
php artisan view:cache 2>/dev/null || echo "View cache failed, continuing..."

# Set proper permissions
echo "==> Setting final permissions..."
chown -R nginx:nginx /var/www/html
chmod -R 755 /var/www/html/storage
chmod -R 755 /var/www/html/bootstrap/cache
chmod 664 /var/www/html/database/database.sqlite 2>/dev/null || true

echo "==> Laravel setup completed, starting web server..."

# Start the original start script from the base image
exec /start.sh