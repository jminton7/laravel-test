FROM richarvey/nginx-php-fpm:3.1.6

# Copy application files
COPY . /var/www/html

# Set working directory
WORKDIR /var/www/html

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

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

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
    echo "LOG_CHANNEL=stderr" >> .env && \
    echo "DB_CONNECTION=sqlite" >> .env && \
    echo "DB_DATABASE=/var/www/html/database/database.sqlite" >> .env && \
    echo "CACHE_DRIVER=file" >> .env && \
    echo "SESSION_DRIVER=file" >> .env && \
    echo "SESSION_LIFETIME=120" >> .env && \
    echo "QUEUE_CONNECTION=sync" >> .env && \
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