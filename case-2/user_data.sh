#!/bin/bash
set -euxo pipefail
exec > /var/log/bootstrap.log 2>&1

dnf -y install nginx
systemctl enable --now nginx

# Remove welcome conf and set explicit server block
rm -f /usr/share/nginx/html/index.html || true
rm -f /etc/nginx/default.d/welcome.conf || true

cat >/etc/nginx/conf.d/webapp.conf <<'NGINX'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
NGINX

mkdir -p /var/www/html
cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html>
  <head><title>Case-2 Standalone</title></head>
  <body style="font-family: system-ui, sans-serif">
    <h1>SSM Patch Manager Demo</h1>
    <p>Served by: __HOSTNAME__</p>
  </body>
</html>
HTML
sed -i "s/__HOSTNAME__/$(hostname -f)/" /var/www/html/index.html
nginx -t && systemctl restart nginx

# Optional: mount extra EBS at /data (NVMe/xvdb-safe)
# EXTRA_DISK="$(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}' | grep -Ev '^(nvme0n1|xvda)$' | head -n1 || true)"
# if [[ -n "${EXTRA_DISK}" ]]; then
#   DEV="/dev/${EXTRA_DISK}"
#   if ! blkid "${DEV}" >/dev/null 2>&1; then mkfs -t xfs "${DEV}"; fi
#   mkdir -p /data
#   UUID="$(blkid -s UUID -o value "${DEV}")"
#   grep -q "${UUID}" /etc/fstab || echo "UUID=${UUID} /data xfs defaults,nofail 0 2" >> /etc/fstab
#   mount -a || mount "${DEV}" /data || true
# fi

# echo "Bootstrap complete."