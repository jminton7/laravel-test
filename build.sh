#!/usr/bin/env bash
set -o errexit

echo "==> Starting build process..."
echo "==> Current directory: $(pwd)"

# Install PHP dependencies in the correct location
echo "==> Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader --no-interaction

# Install Node dependencies and build assets
echo "==> Installing Node dependencies..."
npm ci --only=production

echo "==> Building frontend assets..."
npm run build

# Create database directory and file
echo "==> Setting up SQLite database..."
mkdir -p database
touch database/database.sqlite
chmod 664 database/database.sqlite
chmod 775 database

echo "==> Build completed successfully"