# Use official NGINX image as base
FROM nginx:alpine

# Set working directory in container
WORKDIR /usr/share/nginx/html

# Remove default NGINX static files
RUN rm -rf ./*

# Copy app content from repo into container
COPY . .

# Expose port 80 for the web server
EXPOSE 80

# Start NGINX in foreground
CMD ["nginx", "-g", "daemon off;"]
# End of Dockerfile