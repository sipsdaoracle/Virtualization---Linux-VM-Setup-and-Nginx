#!/bin/bash

# Error handling function
handle_error() {
    echo "Error: $1"
    exit 1
}

# Create NGINX group
sudo groupadd nginx || handle_error "Failed to create NGINX group."

# Create NGINX user
sudo useradd -g nginx nginx || handle_error "Failed to create NGINX user."

# Install Dependencies
sudo apt update -y && sudo apt-get install -y git build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libgd-dev libxml2 libxml2-dev uuid-dev

# Download Nginx Source Code
NGINX_VERSION="1.20.2"
wget "http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz" || handle_error "Failed to download Nginx source code."
tar -zxvf "nginx-$NGINX_VERSION.tar.gz" || handle_error "Failed to extract Nginx source code."
cd "nginx-$NGINX_VERSION" || handle_error "Failed to navigate to Nginx source directory."

# Build & Install Nginx
./configure \
    --prefix=/etc/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/run/nginx.pid \
    --sbin-path=/usr/sbin/nginx \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_stub_status_module \
    --with-http_realip_module \
    --with-file-aio \
    --with-threads \
    --with-stream \
    --with-stream_ssl_preread_module || handle_error "Failed to configure Nginx."
make || handle_error "Failed to build Nginx."
sudo make install || handle_error "Failed to install Nginx."

# Create Systemd File
sudo tee /lib/systemd/system/nginx.service > /dev/null << EOF
[Unit]
Description=Nginx Custom From Source
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/usr/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT \$MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
sudo systemctl daemon-reload

# Enable Nginx service
sudo systemctl enable nginx

# Create Logrotate File
sudo tee /etc/logrotate.d/nginx > /dev/null << EOF
/var/log/nginx/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    prerotate
            if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
                    run-parts /etc/logrotate.d/httpd-prerotate; \
            fi \
    endscript
    postrotate
            invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
EOF

# Start Nginx service
sudo service nginx start