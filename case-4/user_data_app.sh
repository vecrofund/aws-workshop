#!/bin/bash
dnf -y install nginx
systemctl enable --now nginx
echo "<h1>Hybrid demo from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
systemctl restart nginx