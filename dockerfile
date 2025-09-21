FROM php:8.2-fpm

# Install Nginx and utilities
RUN apt-get update && apt-get install -y nginx supervisor && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Copy PHP app
COPY website/ /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Copy Nginx config
COPY nginx.conf /etc/nginx/sites-enabled/default

# Copy Supervisor config to manage PHP-FPM + Nginx
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80
EXPOSE 80

# Start Supervisor
CMD ["/usr/bin/supervisord", "-n"]

# End of Dockerfile