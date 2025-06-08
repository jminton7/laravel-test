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

# Laravel config
ENV APP_ENV production
ENV APP_DEBUG false
ENV APP_URL https://laravel-test-fzx8.onrender.com
ENV LOG_CHANNEL stderr
ENV DB_CONNECTION sqlite
ENV DB_DATABASE /var/www/html/database/database.sqlite

# Allow composer to run as root
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install dependencies and setup Laravel
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Create .env file
RUN printf "APP_NAME=Laravel\nAPP_ENV=production\nAPP_KEY=\nAPP_DEBUG=false\nAPP_URL=https://laravel-test-fzx8.onrender.com\nLOG_CHANNEL=stderr\nDB_CONNECTION=sqlite\nDB_DATABASE=/var/www/html/database/database.sqlite\nCACHE_DRIVER=file\nSESSION_DRIVER=file\nQUEUE_CONNECTION=sync\n" > .env

# Setup database and generate key
RUN mkdir -p /var/www/html/database && \
    touch /var/www/html/database/database.sqlite && \
    APP_KEY="base64:$(openssl rand -base64 32)" && \
    sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|" .env

# Set permissions
RUN chown -R nginx:nginx /var/www/html && \
    chmod -R 755 /var/www/html/storage && \
    chmod -R 755 /var/www/html/bootstrap/cache && \
    chmod 664 /var/www/html/database/database.sqlite

# Remove the custom start script - let the base image handle everything
# The base image should automatically bind to $PORT