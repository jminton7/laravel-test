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

RUN cat .env && php artisan config:show

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Generate APP_KEY and create .env file
RUN APP_KEY_GENERATED="base64:$(openssl rand -base64 32)" && \
    printf "APP_NAME=Laravel\nAPP_ENV=production\nAPP_KEY=%s\nAPP_DEBUG=false\nAPP_URL=https://laravel-test-fzx8.onrender.com\nLOG_CHANNEL=stderr\nDB_CONNECTION=sqlite\nDB_DATABASE=/var/www/html/database/database.sqlite\nCACHE_DRIVER=file\nSESSION_DRIVER=file\nSESSION_LIFETIME=120\nQUEUE_CONNECTION=sync\n" "$APP_KEY_GENERATED" > .env

# Setup database
RUN mkdir -p /var/www/html/database && \
    touch /var/www/html/database/database.sqlite

# Run Laravel setup commands
RUN php artisan config:clear && \
    php artisan migrate --force && \
    php artisan config:cache && \
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