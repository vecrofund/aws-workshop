#!/bin/bash
# Hardened bootstrap for AL2023
set -euxo pipefail
exec > /var/log/bootstrap.log 2>&1

# 1) Install & start nginx
dnf -y install nginx amazon-efs-utils nfs-utils
systemctl enable --now nginx

# 2) Write custom homepage (done EARLY so demo always shows our page)
cat >/usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html>
  <head><title>Scalable WebApp</title></head>
  <body style="font-family: sans-serif;" background="#f0f0f0">
    <h1>Hello from Auto Scaling EC2! - V2 here</h1>
    <p>Served by: __HOSTNAME__</p>
  </body>
</html>
HTML

# Replace placeholder with actual hostname (expand now)
sed -i "s/__HOSTNAME__/$(hostname -f)/" /usr/share/nginx/html/index.html
systemctl restart nginx

# 3) Find the extra EBS disk (NVMe on Nitro or xvdb on older mappings)
#    We exclude the root disk (nvme0n1/xvda) and pick the first other disk.
# EXTRA_DISK="$(lsblk -ndo NAME,TYPE | awk '$2=="disk"{print $1}' | grep -Ev '^(nvme0n1|xvda)$' | head -n1 || true)"

# if [[ -n "${EXTRA_DISK}" ]]; then
#   DEV_PATH="/dev/${EXTRA_DISK}"
#   echo "Discovered extra disk at ${DEV_PATH}"

#   # Create filesystem only if the disk doesn't already have one
#   if ! blkid "${DEV_PATH}" >/dev/null 2>&1; then
#     mkfs -t xfs "${DEV_PATH}"
#   fi

#   mkdir -p /data
#   # Find a stable device name for fstab (prefer /dev/disk/by-uuid)
#   UUID="$(blkid -s UUID -o value "${DEV_PATH}")"
#   if ! grep -q "${UUID}" /etc/fstab; then
#     echo "UUID=${UUID} /data xfs defaults,nofail 0 2" >> /etc/fstab
#   fi
#   mount -a || mount "${DEV_PATH}" /data || true
# else
#   echo "No extra non-root disk found; skipping /data setup."
# fi


# 4) Mount EFS to /mnt/efs (if EFS is available)
# EFS_DNS_NAME="fs-0be1de7045d5059f6.efs.us-east-1.amazonaws.com"  # Replace with your EFS DNS name
# if ping -c 1 -W1 "${EFS_DNS_NAME}" >/dev/null 2>&1; then
#   mkdir -p /mnt/efs
#   if ! grep -q "${EFS_DNS_NAME}" /etc/fstab; then
#     echo "${EFS_DNS_NAME}:/ /mnt/efs efs defaults,_netdev 0 0" >> /etc/fstab
#   fi
#   mount -a || mount -t efs "${EFS_DNS_NAME}":/mnt/efs || true
# else
#   echo "EFS ${EFS_DNS_NAME} not reachable; skipping EFS mount."
# fi    
# echo "Bootstrap complete."
mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 10.0.1.195:/ /mnt/efs