#!/bin/bash
# Restart Nginx to pick up any changes
echo "CodeDeploy Hook: Running restart_server.sh..."
systemctl restart nginx
