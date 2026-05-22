#!/bin/bash
# Update package list and ensure Nginx is installed
echo "CodeDeploy Hook: Running install_dependencies.sh..."
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    yum install -y nginx
fi

# Enable Nginx on system boot
systemctl enable nginx
