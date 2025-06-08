FROM richarvey/nginx-php-fpm:3.1.6

# Install Node.js for Vite build
RUN apk add --no-cache nodejs npm

# Copy application files
COPY . /var/www/html

RUN sed -i 's/\*\*DIR\*\*/__DIR__/g' /var/www/html/routes/web.php

RUN mkdir -p /var/www/html/app/Providers && \
    echo '<?php' > /var/www/html/app/Providers/AppServiceProvider.php && \
    echo 'namespace App\Providers;' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo 'use Illuminate\Support\ServiceProvider;' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo 'use Illuminate\Support\Facades\URL;' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo 'class AppServiceProvider extends ServiceProvider' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '{' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '    public function boot()' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '    {' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '        if (config("app.env") === "production") {' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '            URL::forceScheme("https");' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '        }' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '    }' >> /var/www/html/app/Providers/AppServiceProvider.php && \
    echo '}' >> /var/www/html/app/Providers/AppServiceProvider.php

# Set working directory
WORKDIR /var/www/html

# Fix nginx-php-fpm socket configuration
RUN echo 'server {' > /etc/nginx/sites-available/default && \
    echo '    listen 80 default_server;' >> /etc/nginx/sites-available/default && \
    echo '    root /var/www/html/public;' >> /etc/nginx/sites-available/default && \
    echo '    index index.php index.html;' >> /etc/nginx/sites-available/default && \
    echo '    server_name _;' >> /etc/nginx/sites-available/default && \
    echo '    location / {' >> /etc/nginx/sites-available/default && \
    echo '        try_files $uri $uri/ /index.php?$query_string;' >> /etc/nginx/sites-available/default && \
    echo '    }' >> /etc/nginx/sites-available/default && \
    echo '    location ~ \.php$ {' >> /etc/nginx/sites-available/default && \
    echo '        fastcgi_pass 127.0.0.1:9000;' >> /etc/nginx/sites-available/default && \
    echo '        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' >> /etc/nginx/sites-available/default && \
    echo '        include fastcgi_params;' >> /etc/nginx/sites-available/default && \
    echo '    }' >> /etc/nginx/sites-available/default && \
    echo '}' >> /etc/nginx/sites-available/default

# Image config
ENV SKIP_COMPOSER 0
ENV WEBROOT /var/www/html/public
ENV PHP_ERRORS_STDERR 1
ENV RUN_SCRIPTS 1
ENV REAL_IP_HEADER 1


# Laravel config with file sessions
ENV APP_ENV production
ENV APP_DEBUG false
ENV APP_URL https://laravel-test-fzx8.onrender.com
ENV LOG_CHANNEL stderr
ENV DB_CONNECTION sqlite
ENV DB_DATABASE /var/www/html/database/database.sqlite
ENV SESSION_DRIVER file

# Allow composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

 
# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Install Node dependencies and build assets
RUN npm ci --only=production && \
    npm run build && \
    ls -la public/build/ && \
    cat public/build/manifest.json

# Setup database first
RUN mkdir -p /var/www/html/database && \
    touch /var/www/html/database/database.sqlite

# Create .env file
RUN cp .env.example .env 2>/dev/null || echo "No .env.example found, creating minimal .env"

# Generate APP_KEY and update .env
RUN echo "APP_NAME=Laravel" > .env && \
    echo "APP_ENV=production" >> .env && \
    echo "APP_DEBUG=false" >> .env && \
    echo "APP_URL=https://laravel-test-fzx8.onrender.com" >> .env && \
    echo "ASSET_URL=https://laravel-test-fzx8.onrender.com" >> .env && \
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "DB_CONNECTION=sqlite" >> .env && \
    echo "DB_DATABASE=/var/www/html/database/database.sqlite" >> .env && \
    echo "CACHE_DRIVER=file" >> .env && \
    echo "SESSION_DRIVER=file" >> .env && \
    echo "SESSION_LIFETIME=120" >> .env && \
    echo "SESSION_SECURE_COOKIE=true" >> .env && \
    echo "SESSION_SAME_SITE_COOKIE=lax" >> .env && \
    echo "QUEUE_CONNECTION=sync" >> .env && \
    echo "INERTIA_SSR_ENABLED=false" >> .env && \
    echo "FORCE_HTTPS=true" >> .env && \
    echo "APP_KEY=" >> .env

# Generate and set the APP_KEY
RUN php artisan key:generate --force

# Clear config and run setup
RUN php artisan config:clear

# Verify setup before migrations
RUN php -r "echo 'PHP Version: ' . phpversion() . PHP_EOL;" && \
    php artisan --version

# Run migrations
RUN php artisan migrate --force || echo "Migration failed, continuing..."

# Cache configurations
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Set permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache && \
    chmod 664 /var/www/html/database/database.sqlite && \
    mkdir -p /var/www/html/storage/framework/sessions && \
    chmod -R 755 /var/www/html/storage/framework/sessions

# Expose port
EXPOSE 80