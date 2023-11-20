!/bin/bash

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
LOAD_BALANCER_IP="192.168.95.139"
VM1_IP="192.168.95.140"
VM2_IP="192.168.95.141"
HEALTH_CHECK_ENDPOINT="/health"  # Customize as per your application
SSL_CERTIFICATE_PATH="/path/to/ssl/certificate.crt"  # Customize as per your SSL certificate

# Configure Nginx as a load balancer
configure_load_balancer() {
    # Backup the existing Nginx configuration
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

    # Configure Nginx main configuration file
    cat > /etc/nginx/nginx.conf <<EOF
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server $VM1_IP;
        server $VM2_IP;
        # Add more backend servers if needed
    }

    server {
        listen 80;
        listen [::]:80;
        server_name $LOAD_BALANCER_IP;

        location / {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
            proxy_set_header Host \$host;
        }

        # Uncomment the following block for HTTPS/SSL termination
        # listen 443 ssl;
        # listen [::]:443 ssl;
        # ssl_certificate $SSL_CERTIFICATE_PATH;
        # ssl_certificate_key $SSL_CERTIFICATE_KEY_PATH;
        # ssl_protocols TLSv1.2 TLSv1.3;
        # ssl_ciphers HIGH:!aNULL:!MD5;
        # ssl_prefer_server_ciphers on;
        # location / {
        #     proxy_pass http://backend;
        #     proxy_http_version 1.1;
        #     proxy_set_header Connection "";
        #     proxy_set_header Host \$host;
        # }
    }

    #Uncomment the following block for health check endpoint
     server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
         location $HEALTH_CHECK_ENDPOINT {
             return 200 "OK";
         }
     }
}
EOF

    # Uncomment the above block to enable health check endpoint

    # Uncomment and customize the SSL-related configuration if SSL termination is required
    # Replace $SSL_CERTIFICATE_PATH with the actual SSL certificate file path
    # Uncomment and customize the health check endpoint configuration if required
}

# Restart Nginx
restart_nginx() {
    systemctl restart nginx || handle_error "Failed to restart Nginx."
}

# Main execution
configure_load_balancer
restart_nginx