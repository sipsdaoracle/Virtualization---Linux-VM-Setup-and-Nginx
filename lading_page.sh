#!/bin/bash

# Error handling function
handle_error() {
    echo "Error: $1"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Variables
VM1_ROOT_DIR="/etc/nginx/html/vm1"
VM2_ROOT_DIR="/etc/nginx/html/vm2"
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"
NGINX_SITES_ENABLED="/etc/nginx/sites-enabled"

# Create landing pages
create_landing_pages() {
    # Create VM1 root directory if it doesn't exist
    if [ ! -d "$VM1_ROOT_DIR" ]; then
        mkdir -p "$VM1_ROOT_DIR"
    fi

    # Create VM2 root directory if it doesn't exist
    if [ ! -d "$VM2_ROOT_DIR" ]; then
        mkdir -p "$VM2_ROOT_DIR"
    fi

    # Create landing page for VM1
    echo "<html>
    <head>
        <title>VM1 Landing Page</title>
    </head>
    <body>
        <h1>Welcome to VM1!</h1>
        <p>This is the landing page for VM1.</p>
    </body>
    </html>" > "$VM1_ROOT_DIR/index.html"

    # Create landing page for VM2
    echo "<html>
    <head>
        <title>VM2 Landing Page</title>
    </head>
    <body>
        <h1>Welcome to VM2!</h1>
        <p>This is the landing page for VM2.</p>
    </body>
    </html>" > "$VM2_ROOT_DIR/index.html"
}

# Configure Nginx
configure_nginx() {
    # Create sites-available and sites-enabled directories if they don't exist
    mkdir -p "$NGINX_SITES_AVAILABLE"
     mkdir -p "$NGINX_SITES_ENABLED"

    # Create Nginx configuration for VM1
    echo "server {
        listen 80;
        server_name vm1;
        root $VM1_ROOT_DIR;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }" > "$NGINX_SITES_AVAILABLE/vm1.conf"

    # Create Nginx configuration for VM2
    echo "server {
        listen 80;
        server_name vm2;
        root $VM2_ROOT_DIR;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }" > "$NGINX_SITES_AVAILABLE/vm2.conf"

    # Create symbolic links in sites-enabled
    ln -sf "$NGINX_SITES_AVAILABLE/vm1.conf" "$NGINX_SITES_ENABLED/vm1.conf"
    ln -sf "$NGINX_SITES_AVAILABLE/vm2.conf" "$NGINX_SITES_ENABLED/vm2.conf"

    # Restart Nginx
    systemctl restart nginx || handle_error "Failed to restart Nginx."
}

# Main execution
create_landing_pages
configure_nginx