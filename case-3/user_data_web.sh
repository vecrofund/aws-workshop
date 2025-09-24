#!/bin/bash
set -euxo pipefail
exec > /var/log/bootstrap-web.log 2>&1

dnf -y install nginx
systemctl enable --now nginx

# Clean default and set explicit server that proxies /api to the private app
rm -f /usr/share/nginx/html/index.html || true
rm -f /etc/nginx/default.d/welcome.conf || true

cat >/etc/nginx/conf.d/web.conf <<'NGINX'
server {
  listen 80 default_server;
  server_name _;
  root /var/www/html;
  index index.html;

  location /api/ {
    proxy_pass __APP_URL__/;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
NGINX

mkdir -p /var/www/html
cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html>
  <head><title>Case-3 Web (Public Tier)</title></head>
  <body style="font-family: system-ui, sans-serif">
    <h1>Secure & Resilient Network – Web Tier</h1>
    <p>Served by: __HOSTNAME__</p>
    <p>Try private app via proxy: <a href="/api/hello">/api/hello</a></p>
  </body>
</html>
HTML

sed -i "s/__HOSTNAME__/$(hostname -f)/" /var/www/html/index.html
sed -i "s#__APP_URL__#${app_url}#g" /etc/nginx/conf.d/web.conf

nginx -t && systemctl restart nginx

echo "Web bootstrap complete."